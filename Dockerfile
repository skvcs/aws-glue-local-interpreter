#from openjdk 11 alpine
FROM openjdk:11-jdk-slim
#FROM amazoncorretto:21-alpine3.19-jdk
#FROM public.ecr.aws/amazonlinux/amazonlinux:latest
WORKDIR /root/
#setting the localzone
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split
RUN ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb
RUN ln -s /bin/tar /usr/sbin/tar
#install python and pip
RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y python3-pip && apt-get install -y python3-dev \
    && apt-get install -y python3-venv && apt-get install -y python3-setuptools \
    && apt-get install -y git && apt-get install -y wget && apt-get install -y zip \
    && apt-get install -y unzip && apt-get install -y awscli
#install maven
RUN wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz \
    && tar -xvzf apache-maven-3.9.6-bin.tar.gz \
    && mv apache-maven-3.9.6 /opt/maven \
    && ln -s /opt/maven/bin/mvn /usr/bin/mvn \
    && rm apache-maven-3.9.6-bin.tar.gz
ENV MAVEN_HOME=/opt/maven
ENV PATH=${MAVEN_HOME}/bin:${PATH}
ENV M2_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}
#install spark aws
RUN wget https://aws-glue-etl-artifacts.s3.amazonaws.com/glue-4.0/spark-3.3.0-amzn-1-bin-3.3.3-amzn-0.tgz \
    && tar -xvf spark-3.3.0-amzn-1-bin-3.3.3-amzn-0.tgz \
    && mv spark/ /opt/spark \
    && rm spark-3.3.0-amzn-1-bin-3.3.3-amzn-0.tgz
ENV SPARK_HOME=/opt/spark
ENV PATH=${SPARK_HOME}/bin:${PATH}
ENV PYSPARK_PYTHON_DRIVER=python3
ENV PYSPARK_PYTHON=python3
ENV SPARK_CONF_DIR='set_here'
###install glue libraries
RUN git clone https://github.com/awslabs/aws-glue-libs.git \    
    && chmod -R 770  aws-glue-libs/bin/* \
    && bash aws-glue-libs/bin/glue-setup.sh \
    && cd aws-glue-libs \
    && zip -r awsglue.zip awsglue \
    && mv awsglue.zip /opt/spark/python/lib/ \ 
    && mv jarsv1/* /opt/spark/jars/
RUN rm -rf /root/aws-glue-libs
RUN cd /opt/spark/jars/ && wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar
###python libraries
COPY requirements.txt .
RUN pip3 install --upgrade pip && pip3 install -r requirements.txt && rm requirements.txt
## set pythonpath
ENV PYTHONPATH=/opt/spark/python/lib/awsglue.zip:/opt/spark/python/lib/pyspark.zip:/opt/spark/python/lib/py4j-0.10.9-src.zip:/opt/spark/python
##set dev folder
RUN mkdir developments
WORKDIR /root/developments/
CMD [ "jupyter-notebook", "--ip", "*", "--allow-root", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.password=''", "--NotebookApp.port=8888" ]
#CMD [ "bash" ]