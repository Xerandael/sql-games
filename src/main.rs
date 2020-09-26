#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;

use rocket_contrib::serve::StaticFiles;

#[get("/forums")]
fn forums() -> &'static str {
	"Hello, world!"
}

fn main() {
	rocket::ignite()
      .mount("/", StaticFiles::from(concat!(env!("CARGO_MANIFEST_DIR"), "/static")))
      .mount("/forums", routes![forums]).launch();
}
