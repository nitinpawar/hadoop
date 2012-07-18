#!/bin/sh
set -x

checkExitStatus() {

	if [ $1 -ne 0 ]
	then
		echo $1
		echo "Execution of previous command failed"
		exit 1
	fi
}

#Download Source link for hadoop binaries
hadoopSources=("http://apache.techartifact.com/mirror/hadoop/common/hadoop-0.20.205.0/hadoop-0.20.205.0.tar.gz" "http://apache.techartifact.com/mirror/hadoop/common/hadoop-1.0.3/hadoop-1.0.3.tar.gz")
scriptLocation=`pwd`

echo "For Hadoop 0.20.205 please enter 0"
echo "For Hadoop 1.0.3 please enter 1"

read option

##Check input is an integer
if ((option)) 2>/dev/null; 
then
	option=$((option))
else
	echo "Not a valid input"
	exit 1
fi

#check input value is not greater than download source array length
if [ $option -gt 1 ] 
then
	echo "Invalid option provided"
	exit 1
fi

echo "Please provide directory location for hadoop installtion"
read directoryPath

if [ ! -d $directoryPath ]
then
	mkdir -p $directoryPath
	checkExitStatus $?
fi

cd $directoryPath
checkExitStatus $?


if [ ! -d tmp ]
then
	mkdir tmp
	checkExitStatus $?
fi
cd tmp
#wget ${hadoopSources[${option}]}
checkExitStatus $?

filename=`ls -l hadoop* | awk '{print $NF}'`
tar -zxvhf $filename > /dev/null 2>&1

directoryToMove=`find . -maxdepth 1 -type d -name "hadoop*" `
rm -rf ../$directoryToMove 2> /dev/null 2>&1
mv $directoryToMove ../
cd ../$directoryToMove
cp $scriptLocation/hdfs-site.xml.template conf/
cp $scriptLocation/core-site.xml.template conf/core-site.xml
cp $scriptLocation/mapred-site.xml.template conf/
cd conf
echo "Please provide JAVA_HOME"
read javaHome

#/usr/lib/jvm/jre-1.6.0-openjdk.x86_64/
export JAVA_HOME=$javaHome

echo "Please provide Namenode Metadata directory"
read namenode_directory

echo "Please provide directory for hdfs data"
read hadoop_data_directory

echo "Please provide hadoop tmp directory"
read hadoop_tmp_dir

sed "s|namenode_directory|$namenode_directory|g" hdfs-site.xml.template > tmp
sed "s|hadoop_data_directory|$hadoop_data_directory|g" tmp >  t
sed "s|hadoop_tmp_dir|$hadoop_tmp_dir|g" t > hdfs-site.xml
rm tmp t

echo "Please provide mapred_system_dir"
read mapred_system_dir

echo "Please provide mapred_local_dir"
read mapred_local_dir

sed "s|mapred_system_dir|$mapred_system_dir|g" mapred-site.xml.template > tmp
sed "s|mapred_local_dir|$mapred_local_dir|g" tmp > mapred-site.xml
rm tmp
cd ..

##Format the newly created hadoop file system
bin/hadoop namenode -format

##Start the Namenode
 bin/hadoop-daemon.sh start namenode
echo "sleeping for 5 seconds"
sleep 5
##Start the datanode
 bin/hadoop-daemon.sh start datanode

#start jobtracker
 bin/hadoop-daemon.sh start jobtracker
 bin/hadoop-daemon.sh start tasktracker
