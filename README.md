# postgres-demonstration-persistence

Jakarta Persistence mappings for the [PostgreSQL Demonstration Database](https://postgrespro.com/community/demodb)
(Airlines; database `demo`, schema `bookings`).

Sibling of [mysql-sakila-persistence](https://github.com/jinahya/mysql-sakila-persistence).

## The database

```shell
$ ./_docker-compose-up.sh
```

Brings up `postgres:18` on `localhost:5432`, as `postgres` / `password`, and follows its log; Ctrl-C takes it down
again. Every run starts from an empty cluster: the image loads
[`docker-entrypoint-initdb.d`](docker-entrypoint-initdb.d) in name order,

| file                           | from                                                                                         |
|--------------------------------|----------------------------------------------------------------------------------------------|
| `00-create-database-demo.sql`  | here; gives the dump's leading `DROP DATABASE demo` something to drop                        |
| `demo-20250901-3m.sql.gz`      | https://edu.postgrespro.ru/demo-20250901-3m.sql.gz, unchanged; fetched by [`_fetch-demo.sh`](_fetch-demo.sh) |

The dump is not committed: 139 MB compressed, about 1.3 GB loaded. `_docker-compose-up.sh` runs `_fetch-demo.sh`
first, which downloads it once (about 20 minutes from Korea) and leaves it alone after that; a copy downloaded by
hand into the directory, under that same name, does as well. `DEMO_EDITION=6m`, `1y` or `2y` picks a bigger one. Loading takes a few minutes; the container is `healthy` once `demo` is there.

```shell
$ ./_fetch-demo.sh                 # on its own, e.g. ahead of time
```

```shell
$ docker exec -it postgres-demonstration psql -U postgres -d demo
```

## Building

Two persistence providers, one profile each; `jakarta-ee-11-hibernate-orm` is active by default.

```shell
$ ./_mvn_jakarta_ee_11_test_hibernate-orm.sh              # unit tests, H2 in PostgreSQL mode
$ ./_mvn_jakarta_ee_11_test_eclipselink.sh
$ ./_mvn_jakarta_ee_11_verify_hibernate-orm.sh            # + integration tests, against the database above
$ ./_mvn_jakarta_ee_11_verify_eclipselink.sh
$ ./_mvn_jakarta_ee_11_verify_notests_hibernate-orm.sh    # no database needed
$ ./_mvn_jakarta_ee_11_verify_notests_eclipselink.sh
```
