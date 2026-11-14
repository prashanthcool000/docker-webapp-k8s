# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# vprofile web app  ->  multi-stage build (Maven build  ->  Tomcat 9 runtime)
# Build:  docker build -t <dockerhub-user>/vprofile-app:1.0.0 .
# ---------------------------------------------------------------------------

########## Stage 1: build the WAR ##########
FROM maven:3.9-eclipse-temurin-11 AS build

# container folder
WORKDIR /app

# Copy the POM first
COPY pom.xml .

#download dependencies
RUN mvn dependency

#copy source code
COPY src ./src

#Build application
RUN mvn clean package -DskipTests

########## Stage 2: runtime ##########
# Tomcat 9 = Servlet 4 / javax.* namespace (Tomcat 10+ would break this app)
FROM tomcat:9.0-jre11-temurin-jammy

# 1.Remove Tomcat default applications 2.Create app group 3.Create app user 4.Create temporary folder 5. Give app user ownership of Tomcat folder
RUN rm -rf /usr/local/tomcat/webapps/* \
    && groupadd --system --gid 10001 app \            
    && useradd --system --uid 10001 --gid app app \    
    && mkdir -p /usr/local/tomcat/tmpFiles \           
    && chown -R app:app /usr/local/tomcat        

COPY --from=build --chown=app:app /src/app.war /usr/local/tomcat/webapps/ROOT.war  #copy .war file from build stage to tomcat default folder

# Container-aware JVM sizing (heap = 75% of the pod memory limit)
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom"

USER 10001
EXPOSE 1234
CMD ["catalina.sh", "run"]
