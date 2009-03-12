package cn.edu.thuhpc.hdfsmark.cases;

import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.ini4j.Ini.Section;

public class PutHugeCase extends TestCaseAdapter{

	float size = 1;
	String src = null;
	String dst = null;
	
	@Override
	public String getDesc() {
		return "Put "+size+"GB File into "+dst+" at Hadoop";
	}

	@Override
	public void setup(Section sec) {
		size = Float.valueOf(sec.fetch("size"));
		src = sec.fetch("src");
		dst = sec.fetch("dst");
	}

	@Override
	public void run(FileSystem hdfs, Configuration conf) {
		Path srcp = new Path(src);
	    Path dstp = new Path(dst);
	    
	    try {
		    hdfs.copyFromLocalFile(false, false, srcp, dstp);
		} catch (IOException e) {
			e.printStackTrace();
		}
		
	}

	@Override
	public void cleanup(FileSystem hdfs, Configuration conf) {
	    Path dirp = new Path(dst);
	    try {
	    	hdfs.delete(dirp,true);
		} catch (IOException e) {
			e.printStackTrace();
		}	
	}

}
