## DataType



### Parquet

Nested data format, the basic datatype in Schema are all leaves.

Compress algorithm for nested data format [Striping/Assembly]:

Value、Repetition level、Definition level

#### File Structure

* store binary, cannot r w directly
* self-resolving, the file include data and metadata

[INT64, INT32, BOOLEAN, BINARY, FLOAT, DOUBLE, INT96, FIXED_LEN_BYTE_ARRAY]