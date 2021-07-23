using Godot;
using System;
using Npgsql;
using System.Data;

public class CardBase : MarginContainer
{
	
	public override void _Ready()
	{
//		Console.WriteLine("foo");
//		var conn = new NpgsqlConnection($"Server=127.0.0.1;Port=5432;User Id=postgres;Password=06Ast04Hgt;Database=TripleTriadDb");
//		conn.Open();
//
//		var da = new NpgsqlDataAdapter("SELECT * FROM card", conn);
//		var ds = new DataSet();
//
//		da.Fill(ds);
//
//		foreach(DataRow dr in ds.Tables[0].Rows)
//		{
//			Console.WriteLine(dr["name"]);
//		}
		var border = GetNode<Sprite>("Border");
		border.Scale = RectSize / border.Texture.GetSize();
	}

//  // Called every frame. 'delta' is the elapsed time since the previous frame.
//  public override void _Process(float delta)
//  {
//      
//  }
}
