source("tests/setup.R")

# TODO: This is for development purposes only. Remove this before merging.
test_df <- get_data_from_db("data/cog_8_heterogeneous.sqlite3")
test_df <- prepare_varience_data(test_df)