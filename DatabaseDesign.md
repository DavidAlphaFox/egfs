### (1)Metadata Format Table ###

| **FILEID** | **FILENAME** | **FILESIZE** | **CHUNKS** | **CREATETIME** | **MODIFYTIME** | **ACL** |
|:-----------|:-------------|:-------------|:-----------|:---------------|:---------------|:--------|
|0ef4(64bit) |	  /foo/bar	  |  2097152	    | [ChunkID1, ChunkID5, ChunkID30]	|08年12月14日09时04分|	08年12月14日09时04分|......   |
|0de2	       |/foo/tmp      | 1024         | ChunkID7   |08年12月14日09时04分|	08年12月14日09时04分|......   |


### (2)Chunk Mapping Table ###

| **CHUNKID** | **CHUNKLOCATION** |
|:------------|:------------------|
|ChunkID1	    |[node1,node2,node3] |
|ChunkID5	    |node4              |
|ChunkID7	    |[node5,node6]      |
|ChunkID30	   |node7              |


### (3)Host Info ###

| **IP** | **HOST** | **FREESPACE** | **TOTALSPACE** |
|:-------|:---------|:--------------|:---------------|
|10.0.0.1|  node1	  |0.96T	         |1T              |
|10.0.0.5|  node5	  |1T	            |1T              |


### (4)Data Format ###

| **CHUNKID** | **PATH** | **CREATETIME** | **MODIFYTIME** |
|:------------|:---------|:---------------|:---------------|
|ChunkID1	    |/home/user/data001	|08年12月14日09时04分	|08年12月14日09时04分|
|ChunkID5	    |/home/user/data003	|08年12月14日09时04分	|08年12月14日09时04分|