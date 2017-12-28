We started out with core. Core is a monolith written in PHP and it
uses Doctrine as the database layer. Doctrine is an ORM where you
define your model in PHP and then use a script to generate your
database.

We slowly started writing a new service in Scala. Core still owned the datbase.
The Scala service started to need to run SQL migrations as well.

We didn't want to have two databases. The extra ops work required weren't worth it.

Problems
- Now generating an empty fully migrated databse requires multi repos
- Generating demo data requires more moving parts
