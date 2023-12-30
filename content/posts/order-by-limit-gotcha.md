---
title: "ORDER BY x LIMIT y Gotcha"
date: 2023-12-29T22:25:13+03:00
author: "Timothy Karani"
authorTwitter: "c3n7_luc"
tags: ["sql", "laravel"]
keywords: ["sql", "laravel"]
description: "Perfomance gotcha when doing an ORDER BY x LIMIT y SQL query"
draft: false
---

## Introduction

On a production environment I was watching a query I had just made attempts at optimizing take longer and longer as days went. Usually I would look at `WHERE` clauses to inform me on indexes that need creating or queries that need restructuring but often overlooked `ORDER BY` clauses, turns out both need equal attention.

## Reproduction

I will be using Laravel for this because of easy `EXPLAIN` statements provided by [`barryvdh/laravel-debugbar`](https://github.com/barryvdh/laravel-debugbar) and [`FakerPHP`](`https://fakerphp.github.io/`) that we'll use to seed the database with lots of records.

1. Create a Laravel Project
   ```shell
   $ composer create-project laravel/laravel order-by-gotcha
   ```
2. Update `.env` and set `DB_DATABASE`, `DB_USERNAME` and `DB_PASSWORD`. I will be using `mysql`. You might need to create a database.
3. Create a `Client` model together with a corresponding migration and controller.
   ```shell
   $ php artisan make:model Client -mc
   ```
4. Update the migration. Only the email column is indexed, for future demonstration purposes.
   ```php
   // ...
   $table->string('name');
   $table->string('email')->index();
   $table->string('phone');
   $table->timestamps();
   // ...
   ```
5. Update the `Client` model to make the columns fillable.
   ```php
   // ...
   protected $fillable = [
       'name',
       'email',
       'phone'
   ];
   // ...
   ```
6. Update the `DatabaseSeeder` to seed 1,000,000 clients. This might take a bit, 6 min on my end (SSD, 8 Cores):

   ```php
    public function run(): void
    {
        $records = [];
        $start_time = microtime(true);
        $iter_start_time = microtime(true);
        for ($i = 0; $i < 1_000_000; $i++) {
            // For logging, just to see stuff works
            if ($i > 0 && (($i % 10_000) == 0)) {
                $end_time = microtime(true);
                $cumulative = $end_time - $start_time;
                $iter = $end_time - $iter_start_time;

                $this->command->info("$i - Cumulative: $cumulative, Iter: $iter");
                $iter_start_time = microtime(true);
            }

            $records[] = [
                'name' => fake()->name(),
                'email' => fake()->email(),
                'phone' => fake()->phoneNumber(),
                'created_at' => fake()->dateTimeBetween('-10 Years', 'now'),
                'updated_at' => fake()->dateTimeBetween('-10 Years', 'now'),
            ];

            // Bulk insert every 1000 records
            if ($i > 0 && (($i % 1_000) == 0)) {
                DB::table('clients')->insert($records);
                $records = [];
            }
        }
    }
   ```

7. Now on to the `ClientController` class, with the following methods:

   ```php
    public function index()
    {
        $client =  Client::query()->latest()
            ->first();

        return view('welcome', compact('client'));
    }

    public function index_with_where_clause()
    {
        $filter = 'ca';
        $client =  Client::query()
            ->where('email', 'like', "%{$filter}%")
            ->latest()
            ->first();

        return view('welcome', compact('client'));
    }

    public function index_order_by_email()
    {
        $client =  Client::query()
            ->latest('email')
            ->first();

        return view('welcome', compact('client'));
    }

    public function index_order_by_id()
    {
        $client =  Client::query()
            ->latest('id')
            ->first();

        return view('welcome', compact('client'));
    }
   ```

8. Clean up `welcome.blade.php`, just show the client name:

   ```php
   <!DOCTYPE html>
   <html>
   <head>
       <title>Laravel</title>
   </head>
   <body>
       {{ $client->name }}
   </body>
   </html>
   ```

9. Update `web.php` to add the route:
   ```php
    Route::get('/', [ClientController::class, 'index']);
    Route::get('/with_where', [ClientController::class, 'index_with_where_clause']);
    Route::get('/order_by_email', [ClientController::class, 'index_order_by_email']);
    Route::get('/order_by_id', [ClientController::class, 'index_order_by_id']);
   ```
10. Add `laravel-debugbar` and publish the config:
    ```shell
    $ composer require barryvdh/laravel-debugbar --dev
    $ php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"
    ```
11. Enable explain output by editing `config/debugbar.php`. Scroll until you find the setting then update it as follows:
    ```php
    'explain' => [                 // Show EXPLAIN output on queries
        'enabled' => true,
        'types' => ['SELECT'],     // Deprecated setting, is always only SELECT
    ],
    ```
12. Run migrations and seed the database:
    ```shell
    $ php artisan migrate --seed
    ```
13. Start the server
    ```shell
    $ php artisan serve
    ```

## Exploring Performance

- When we open [http://localhost:8000/](http://localhost:8000/), this is what the debug bar shows us as the `EXPLAIN` output:

  ```sql
  explain select * from `clients` order by `created_at` desc limit 1
  ```

  | table   | type | possible_keys | key | key_len | ref | rows   | Extra          |
  | ------- | ---- | ------------- | --- | ------- | --- | ------ | -------------- |
  | clients | ALL  |               |     |         |     | 999001 | Using filesort |

  999001 records are being loaded into memory! And the query takes `904ms`. Not good. On production, a comparable query was taking `1.7 seconds`.

- You might think that a query with a where clause would help things, let's open [http://localhost:8000/with_where](http://localhost:8000/with_where) to see if that's the case:

  ```sql
  explain select * from `clients` where `email` like '%ca%' order by `created_at` desc limit 1
  ```

  | table   | type | possible_keys | key | key_len | ref | rows   | Extra                       |
  | ------- | ---- | ------------- | --- | ------- | --- | ------ | --------------------------- |
  | clients | ALL  |               |     |         |     | 999001 | Using where; Using filesort |

  Still way to many records being loaded with the operation taking `767ms`.

- We added an index on the `email` column though? Maybe let's use it when ordering instead of `created_by`. Let's open [http://localhost:8000/order_by_email](http://localhost:8000/order_by_email):

  ```sql
  explain select * from `clients` order by `email` desc limit 1
  ```

  | table   | type  | possible_keys | key                 | key_len | ref | rows | Extra |
  | ------- | ----- | ------------- | ------------------- | ------- | --- | ---- | ----- |
  | clients | index |               | clients_email_index | 1022    |     | 1    |       |

  Only one row is loaded, and the index is used with the select operation taking `2.46ms`. Just like that we get a significant bump in performance. On production the query went from `1.7 seconds` to ~`70ms`. Now you can either add an index to the `created_at` column or leverage the primary key which is indexed by default. The `email` index in this example was just to show indexes help in `ORDER BY` statements.

- Let's use the `PRIMARY KEY` for ordering [http://localhost:8000/order_by_id](http://localhost:8000/order_by_id):

  ```sql
  explain select * from `clients` order by `id` desc limit 1
  ```

  | table   | type  | possible_keys | key     | key_len | ref | rows | Extra |
  | ------- | ----- | ------------- | ------- | ------- | --- | ---- | ----- |
  | clients | index |               | PRIMARY | 8       |     | 1    |       |

  This one takes `1.74ms`, doesn't load close to a million records to memory, looks alright.

## TL;DR

Use indexed columns when using `ORDER BY` clauses.

## Resources for Further Exploration

- [Code (on GitHub)](https://github.com/c3n7-learning/order-by-gotcha)
- [8.2.1.16 ORDER BY Optimization](https://dev.mysql.com/doc/refman/8.0/en/order-by-optimization.html)
