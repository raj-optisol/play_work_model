Bootstrap:
----------

```
Clone
bundle install
bundle exec rake db:create:all db:migrate
```

A rails console should show you 0 models per above.


Data acquisition:
-----------------

Works with the results of the bin/download-migration-data from
kyck_registrar_web.  Those files have DOS/Mac linefeeds.  I stripped them out by
opening the file in nano, and then just writing it back.

Here's what you can do to load the data, pgloader.conf is included

```
bin/download-migration-data
git clone https://github.com/dimitri/pgloader.git
cp migration-loader.conf pgloader/.
cd pgloader
git checkout -b pgloader-v2 -t origin/pgloader-v2
```

Then, after you copy the line-rewritten CSV files in from wherever into the
pgloader directory AND double-check that migration-loader.conf has the correct
DB name for you:

```
cp pgloader
./pgloader.py -Tvc migration-loader.conf member address team club passcard_request
```

That's as far as I got.

Integration choices:
--------------------

* Run this from developer laptops when configured to have ORIENTDB_URL pointed
  to remote systems as appropriate.
