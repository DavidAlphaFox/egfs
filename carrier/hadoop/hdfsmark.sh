#!/bin/bash
/usr/java/default/bin/java -Xmx1000m -Dhadoop.log.dir=/home/lkliu/hadoop-0.19.0/bin/../logs -Dhadoop.log.file=hadoop.log -Dhadoop.home.dir=/home/lkliu/hadoop-0.19.0/bin/.. -Dhadoop.id.str= -Dhadoop.root.logger=INFO,console -Djava.library.path=/home/lkliu/hadoop-0.19.0/bin/../lib/native/Linux-i386-32 -classpath .:/home/lkliu/ini4j-0.4.0.jar:/home/lkliu/hadoop-0.19.0/bin/../conf:/usr/java/default/lib/tools.jar:/home/lkliu/hadoop-0.19.0/bin/..:/home/lkliu/hadoop-0.19.0/bin/../hadoop-0.19.0-core.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-cli-2.0-SNAPSHOT.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-codec-1.3.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-httpclient-3.0.1.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-logging-1.0.4.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-logging-api-1.0.4.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/commons-net-1.4.1.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/hsqldb-1.8.0.10.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jets3t-0.6.1.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jetty-5.1.4.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/junit-3.8.1.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/kfs-0.2.0.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/log4j-1.2.15.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/oro-2.0.8.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/servlet-api.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/slf4j-api-1.4.3.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/slf4j-log4j12-1.4.3.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/xmlenc-0.52.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jetty-ext/commons-el.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jetty-ext/jasper-compiler.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jetty-ext/jasper-runtime.jar:/home/lkliu/hadoop-0.19.0/bin/../lib/jetty-ext/jsp-api.jar:./HdfsBenchmark.jar cn.edu.thuhpc.hdfsmark.HdfsBenchmark

#remove local files created by tht scripts above
rm -rf linux