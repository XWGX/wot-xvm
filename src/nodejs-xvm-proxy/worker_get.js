var http = require("http"),
    async = require("async"),
    utils = require("./utils"),
    settings = require("./settings").settings,
    db = require("./worker_db"),
    tcalc = require("./tcalc/tcalc"),
    status = require("./worker_status");

exports.processRemotes = function(cached, update, response, times) {
    times.push({"n":"process","t":new Date()});

    var urls = { };

//utils.debug("processRemotes()");

    // FIXIT: why this don't work?
    //    for (var id in update) ...
    // symptoms: makeSingleRequest args are wrong (always the last item values)
    var up = [];
    for (var id in update)
        up.push(id);
    up.forEach(function(id) {
        var pdata = update[id];
        var srv = getFreeConnection(pdata.servers);

        if (srv.error) {
            if (pdata.cache)
                pdata.cache.st = srv.error;
            else
                pdata.cache = {_id:id,st:srv.error};
            cached[id] = pdata.cache;
            delete update[id];
            process.send({usage:1, max_conn:1});
            return;
        }

        delete pdata.servers;
        pdata.server = srv;
        urls[id] = function(callback) { makeSingleRequest(id, srv, callback); }
    });

//    response.end("DEBUG:\nupdate: " + JSON.stringify(update) + "\ncache: " + JSON.stringify(cached)); return;

//    async.series(urls, function(err, results) { asyncCallback(err, results, cached, update, response, times) });
    async.parallel(urls, function(err, results) { asyncCallback(err, results, cached, update, response, times) });
}

// PRIVATE

// find free connection (connections balancer)
var getFreeConnection = function(servers) {
    var now = new Date();
    var totalAvail = 0;
    var wait = true;
    for (var i in servers)
    {
        var srv = servers[i];
        var sst = status.serverStatus[srv.id];

        // Do not execute requests some time after error response
        if (sst.lastErrorDate) {
            if ((now - sst.lastErrorDate) < settings.lastErrorTtl) {
                srv.avail = 0;
                continue;
            }
            if (settings.lastErrorTtl > 1000)
                utils.log("INFO:  [" + sst.host + "] resumed");
            sst.lastErrorDate = null;
            sst.error_shown = false;
        }

        wait = false;
        srv.avail = Math.max(0, sst.maxConnections - sst.connections);
        totalAvail += srv.avail;
    }

    if (wait)
        return {error:"wait"};

    if (totalAvail <= 0)
        return {error:"max_conn"};

    var n = Math.floor(Math.random()*totalAvail);
    for (var i in servers)
    {
        var srv = servers[i];
        if (srv.avail > n) {
            status.serverStatus[srv.id].connections++;
            return srv;
        }
        n -= srv.avail;
    }

    utils.log("getFreeConnection(): internal error");
    return {error:"fail"};
}


// execute request for single player id
var makeSingleRequest = function(id, server, callback) {

    //utils.debug("id:"+ id + " server:" + server.id);
    process.send({usage:1, serverId:server.id, connections:1});

    var options = {
        host: server.host,
        port: server.port,
        path: "/uc/accounts/" + id + "/api/" + server.api + "/?source_token=Intellect_Soft-WoT_Mobile-unofficial_stats",
        //agent: agent,
        headers: {
            // 'connection': 'keep-alive'
            'connection': 'close'
        }
    }

    var done = false;
    var reqTimeout = setTimeout(function() {
        done = true;
        var err = "[" + server.host + "] Http timeout: " + server.timeout;
        onRequestDone(server, err);
//        utils.debug(err);
        callback(null, { __status: "timeout" });
    }, server.timeout);

//callback(null, { __status: "debug" }); return;
//utils.debug("START: " + id);
    http.get(options, function(res) {
        if (res.statusCode != 200) {
            clearTimeout(reqTimeout);
            if (done)
                return;
            var err = "[" + server.host + "] Http error: bad status code: " + res.statusCode;
            onRequestDone(server, err);
            //utils.debug(err);
            callback(null, { __status: res.statusCode });
            return;
        }

        res.setEncoding("utf8");
        var responseData = "";
        res.on("data", function(chunk) {
            // TODO check valid JSON string and terminate immediately if not
            //if (responseData == "" && chunk[0] != "{")
            //    return;
            responseData += chunk;
        });
        res.on("end", function() {
            clearTimeout(reqTimeout);
            if (done)
                return;
            try {
                var result = JSON.parse(responseData);
            } catch(e) {
                var str;
                if (responseData[0] != "{")
                    str = "(binary)";
                else {
                    str = responseData.replace(/[ \t\n\r\x00-\x1F]/g, "");
                    str = str.substr(0, 45) + "~" + str.substr(str.length - 11, 10);
                }
                var err = "[" + server.host + "] JSON.parse:  l=" + responseData.length + ", d=\"" + str + "\"";
                onRequestDone(server, err);
//                utils.debug(err);
                callback(null, { __status: "parse" });
                return;
            }
            //utils.debug("responseData.length = " + responseData.length);
            onRequestDone(server);
//            utils.debug("DONE: " + id);
            callback(null, result);
        });
    }).on("error", function(e) {
        clearTimeout(reqTimeout);
        if (done)
            return;
        done = true;
        var err = "[" + server.host + "] Http error: " + e
        onRequestDone(server, err);
//        utils.debug(err);
        callback(null, { __status: "error" });
    });
}

var onRequestDone = function(server, error) {
    var now = new Date();
    var sst = status.serverStatus[server.id];
    sst.connections--;
    process.send({usage:1, serverId:server.id, connections:-1, fail:error?true:false});

    // HTTP connections balancer
    if(!sst.lastMaxConnectionUpdate || (now - sst.lastMaxConnectionUpdate) > (error ? 1000 : 5000)) {
        sst.lastMaxConnectionUpdate = now;
        var oldMaxConn = sst.maxConnections;
        sst.maxConnections = Math.max(1, Math.min(server.maxconn, sst.maxConnections + (error ? -5 : 1)));
        process.send({usage:1, serverId:server.id, maxConnections:sst.maxConnections-oldMaxConn});
    }

    if (error) {
        sst.lastErrorDate = now;
        if(!sst.error_shown) {
            sst.error_shown = true;
            //utils.log("ERROR: " + error);
            process.send({log:1, msg:"ERROR: "+error});
        }
    }
}

// process received data, update db
var asyncCallback = function(err, results, cached, update, response, times) {

//response.end("DEBUG:" + JSON.stringify(times) + "\nupdate: " + JSON.stringify(update) + "\ncache: " + JSON.stringify(cached) + "\nresults: " + JSON.stringify(results)); return;

    times.push({"n":"rqdone","t":new Date()});

    var now = new Date();
    var result = {
        players: [ ],
        info: status.info,
        server: settings.serverName
    };

    // add cached items to result
    for (var i in cached) {
        result.players.push(_cacheToResult(cached[i]));
        process.send({usage:1, cached:1});
    }
    cached = null;

//response.end("DEBUG:\n\nupdate: " + JSON.stringify(update) + "\n\nresult: " + JSON.stringify(result) + "\n\nresults: " + JSON.stringify(results)); return;

    // process retrieved items
    for (var id in update) {
        var item = results[id];
        if (!item) {
            utils.log("internal error in worker_get.js:asyncCallback(): !item, id=" + id + ", err= " + err);
            result.players.push({id:id, status:"fail", date:now});
            continue;
        }

        // check for errors
        if (item.__status) {
            result.players.push(_prepareFallbackRes(update[id], id, item.__status));
            continue;
        }

        // check for errors from stat server
        if (item.status == "error") {
            var res = _prepareFallbackRes(update[id], id, "error");
            switch(item.status_code) {
                case "API_UNKNOWN_SERVER_ERROR":
                    res.status = "api_error";
                    break;
                case "ACCOUNTS_PROFILE_CLOSED":
                    res.status = "closed";
                    break;
                case "ACCOUNTS_ACCOUNT_MISSING_OR_UNINITIALIZED":
                    res.status = "not_init";
                    break;
                default:
                    res.status = "fail";
                    res.status_code = "Unknown status code: " + item.status_code;
                    utils.log("WARNING: Unknown status code: " + item.status_code + ", id=" + id);
                    break;
            }
            result.players.push(res);
            continue;
        }

        // check for no error
        if (item.status != "ok" || item.status_code != "NO_ERROR") {
            var res = _prepareFallbackRes(update[id], id, "ok");
            res.status = item.status;
            res.status_code = item.status_code;
            result.players.push(res);
            utils.log("internal error: unknown status: " + item.status + ", status_code: " + item.status_code);
            continue;
        }

        // check for correct id
        var _id = parseInt(id);
        if (!_id || _id <= 0) {
            var res = _prepareFallbackRes(update[id], id, "ok");
            res.status = "bad_id";
            result.players.push(res);
            utils.log("internal error: invalid id: " + id);
            continue;
        }

        var pdata = _parseNewPlayerData(_id, item.data);

        // updating db
        db.updatePlayersData(_id, pdata);
        //utils.log("id:" + id + " pdata:" + JSON.stringify(pdata));
        process.send({usage:1, updated:1});

        if (settings.updateMissed == true)
            db.removeMissed(_id);

        if (update[id].vname)
            pdata.vname = update[id].vname;

        result.players.push(_cacheToResult(pdata));

//response.end(JSON.stringify(pl)); return;
//        delete results[id];
     }

    times.push({"n":"processed","t":new Date()});

//response.end("DEBUG:\n\nupdate: " + JSON.stringify(update) + "\n\nresult: " + JSON.stringify(result) + "\n\nresults: " + JSON.stringify(results)); return;

    _printDebugInfo(result.players, times);

//utils.debug("response.end()");

    // return response to client
    response.end(JSON.stringify(result));
}

// service functions

var _cacheToResult = function(item)
{
    var res = {
        id: item._id,
        date: item.dt,
        vname: item.vname,
        status: item.st,
        name: item.nm,
        battles: item.b,
        wins: item.w,
        spo: item.spo,
        hip: item.hip,
        cap: item.cap,
        dmg: item.dmg,
        frg: item.frg,
        def: item.def,
        eff: item.e,
        wn: item.wn,
        twr: item.twr
    }
    if (item.vname && item.v)
        res.v = item.v.name ? item.v : utils.filterVehicleData(item, item.vname);
    return res;
}

var _parseNewPlayerData = function(id, data) {
    // fill global info
    var pdata = {
        _id: parseInt(id),
        dt: new Date(),
        st: "ok",
        nm: data.name,
        b: data.summary.battles_count,
        w: data.summary.wins,
        spo: data.battles.spotted,
        hip: data.battles.hits_percents,
        cap: data.battles.capture_points,
        dmg: data.battles.damage_dealt,
        frg: data.battles.frags,
        def: data.battles.dropped_capture_points,
        v: []
    }

    // fill vehicle data
    for (var i in data.vehicles) {
        var vdata = data.vehicles[i];
        pdata.v.push({
            name: vdata.name.toUpperCase(),
            cl: utils.getVehicleType(vdata.class),
            l: vdata.level,
            b: vdata.battle_count,
            w: vdata.win_count,
            d: vdata.damageDealt,
            f: vdata.frags,
            s: vdata.spotted,
            u: vdata.survivedBattles
        });
    }

    // EFF - wot-news efficiency rating
    pdata.e = utils.calculateEfficiency(pdata);

    // WN - WN rating http://forum.worldoftanks.com/index.php?/topic/184017-
    pdata.wn = utils.calculateWN(pdata);

    // TWR - tourist1984 win rate (aka T-Calc)
    try {
//        utils.log("start calc twr: " + resultItem._id);
//        pdata.twr = tcalc.calc(utils.clone(pdata)).result.toFixed(2);
//        utils.log("pdata.twr=" + pdata.twr + "%" +
//            ", GWR=" + (resultItem.w / pdata.b * 100).toFixed(2) + "%" +
//            ", bc=" + pdata.b +
//            ", id=" + pdata._id);
    } catch (e) { utils.log(e); }

    return pdata;
}

var _prepareFallbackRes = function(item, id, status) {
    id = parseInt(id);

    if (!item.cache) {
        process.send({usage:1, missed:1});
        if (settings.updateMissed == true)
            db.insertMissed(item.id, true);
        return {id:id, date:new Date(), status:status};
    }

    process.send({usage:1, updatesFailed:1});
    if (settings.updateMissed == true)
        db.insertMissed(id, false);
    var res = _cacheToResult(item.cache);
    res.status = status;
    return res;
}

var _printDebugInfo = function(items, times) {
    var now = new Date();
    var duration = now - times[0].t;
    if (duration > 6000) {
        times.push({"n":"end","t":now});
        var str = "";
        for(var i = 1; i < times.length; ++i) {
            if(str != "")
                str += " ";
            str += times[i].n + ":" + String(times[i].t - times[i - 1].t);
        }
        utils.debug("times: " + str);
    }
}
