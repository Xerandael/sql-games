#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;

#[get("/forums")]
fn forums() -> &'static str {
	"Hello, world!"
}

fn main() {
	rocket::ignite()
      .mount("/", StaticFiles::from("/"))
      .mount("/forums", routes![forums]).launch();
}
