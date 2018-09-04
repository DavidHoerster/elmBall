using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

using Dapper;
using MySql.Data;
using MySql.Data.MySqlClient;
using System.Configuration;
using Microsoft.Extensions.Configuration;

namespace agileBall_svr.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SearchController : ControllerBase
    {
        private IConfiguration _config;
        public SearchController(IConfiguration config)
        {
            _config = config;
        }


        // GET api/values
        [HttpGet("{query}")]
        public ActionResult<IEnumerable<Player>> Get(string query)
        {
            var players = FindPlayers(query);

            return players.ToList();
        }


        private IEnumerable<Player> FindPlayers(string query)
        {
            IEnumerable<Player> players = null;
            using (var conn = new MySqlConnection(_config.GetConnectionString("baseballData")))
            {
                conn.Open();
                const string sql = @"SELECT CONCAT_WS(' ',m.nameFirst, m.nameLast) as name, m.playerID FROM lahman2016.master m WHERE m.nameFirst LIKE @name OR m.nameLast LIKE @name ORDER BY m.nameLast, m.nameFirst";
                players = conn.Query<Player>(sql, new { name = $"{query}%" });
            }
            return players;
        }
    }

    public class Player
    {
        public string Name { get; set; }
        public string PlayerId { get; set; }
    }
}