package t::TEST;
use parent qw(Kappa);
use strict;
use warnings;


1;

__DATA__

@@ test_sql
SELECT * FROM TEST;

@@ test_sql2
SELECT * FROM TEST;

@@ test_select_named
SELECT * FROM TEST WHERE value = :value;

@@ test_select_row_named
SELECT * FROM TEST WHERE value = :value;

@@ test_select_all_named
SELECT * FROM TEST WHERE value = :value;

@@ test_select_itr_named
SELECT * FROM TEST WHERE value = :value;

@@ test_select_by_sql
SELECT * FROM TEST WHERE value = ?;

@@ test_select_row_by_sql
SELECT * FROM TEST WHERE value = ?;

@@ test_select_all_by_sql
SELECT * FROM TEST WHERE value = ?;

@@ test_select_itr_by_sql
SELECT * FROM TEST WHERE value = ?;

@@ test_insert_by_execute_query
INSERT INTO TEST (id, value) VALUES (?, ?);

@@ test_insert_by_execute_query_named
INSERT INTO TEST (id, value) VALUES (:id, :value);

