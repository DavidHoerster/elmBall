using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

using Dapper;
using MySql.Data;
using MySql.Data.MySqlClient;

namespace agileBall_svr.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PlayerController : ControllerBase
    {
        // GET api/values
        [HttpGet("{id}")]
        public ActionResult<IEnumerable<PlayerDetail>> Get(string id)
        {
            var player = GetPlayer(id);

            return player.ToList();
        }


        private IEnumerable<PlayerDetail> GetPlayer(string id)
        {
            IEnumerable<PlayerDetail> player = null;
            using (var conn = new MySqlConnection("Server=baseball-data.mysql.database.azure.com; Port=3306; Database=lahman2016; Uid=dhoerster@baseball-data; Pwd=P@ssw0rd;"))
            {
                conn.Open();
                const string sql = @"SELECT CONCAT(m.nameFirst,' ',m.nameLast) as name, m.bbrefID, m.playerID, b.yearID, b.H as Hits, b.HR as HomeRuns, b.RBI as RunsBattedIn
                                    FROM lahman2016.master m INNER JOIN lahman2016.batting b ON m.playerID = b.playerID
                                    WHERE m.playerID = @id
                                    ORDER BY b.yearID DESC";

                player = conn.Query<PlayerDetail>(sql, new { id = id });
            }
            return player;
        }
    }

    public class PlayerDetail
    {
        public string Name { get; set; }
        public string PlayerId { get; set; }
        public string bbrefId {get;set;}
        public int YearId {get;set;}
        public int Hits {get;set;}
        public int HomeRuns {get;set;}
        public int RunsBattedIn {get;set;}
    }
}