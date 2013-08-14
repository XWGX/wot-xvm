﻿using LitJson;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;

namespace wot.Dossier
{
  public static class VehicleInfo
  {
    public static List<VehicleInfoData> data;

    static VehicleInfo()
    {
      data = new List<VehicleInfoData>();
      try
      {
        string game_dir = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);
        string vifn = Path.Combine(game_dir, "res_mods/xvm/res/VehicleInfo.json");
        if (!File.Exists(vifn))
          throw new Exception("Resource file not found: res_mods/xvm/res/VehicleInfo.json");
        JsonData vi = JsonMapper.ToObject(File.ReadAllText(vifn));
        for (int i = 0; i < vi.Count; ++i)
        {
          JsonData jd = vi[i];
          int level = jd.ToInt("level");
          if (level <= 0)
            continue;
          data.Add(new VehicleInfoData()
          {
            vehicleId = jd.ToInt("id"),
            vname = jd.ToString("name"),
            level = level,
            nation = ToIntNation(jd.ToString("nation")),
            vclass = ToIntClass(jd.ToString("type")),
            premium = jd.ToString("premium").ToLower() == "true",
            hp = jd.ToInt("hptop"),
          });
        }
      }
      catch (Exception ex)
      {
        Program.Log(ex.ToString());
      }
    }

    public static VehicleInfoData ByVid(int vid)
    {
      return data.Find(x => x.vid == vid);
    }

    public static int ToIntClass(string vclass)
    {
      switch (vclass.ToUpper())
      {
        case "LT": return 2;
        case "MT": return 3;
        case "HT": return 5;
        case "TD": return 4;
        case "SPG": return 1;
        default:
          throw new Exception("Unknown vehicle class: " + vclass);
      }
    }

    public static int ToIntNation(string nation)
    {
      switch (nation.ToLower())
      {
        case "ussr": return 0;
        case "germany": return 1;
        case "usa": return 2;
        case "china": return 3;
        case "france": return 4;
        case "uk": return 5;
        case "japan": return 6;
        default:
          throw new Exception("Unknown nation: " + nation);
      }
    }
  }

  public class VehicleInfoData
  {
    public int vehicleId;
    public string vname;
    public int level;
    public int nation;
    public int vclass;
    public bool premium;
    public int hp;

    public int vid
    {
      get { return (vehicleId << 8) + (nation << 4); }
    }
  }
}
