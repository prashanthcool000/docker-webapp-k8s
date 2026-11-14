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
RUN mvn dependency:go-offline

#copy source code
COPY src ./src

#Build application
RUN mvn clean package -DskipTests

########## Stage 2: runtime ##########
# Tomcat 9 = Servlet 4 / javax.* namespace (Tomcat 10+ would break this app)
FROM tomcat:9.0-jre11-temurin-jammy

# 1.Remove Tomcat default applications 2.Create app group 3.Create app user 4.Create temporary folder 5. Give app user ownership of Tomcat folder

# syntax=docker/dockerfile:1

# STAGE 1: BUILD
FROM maven:3.9-eclipse-temurin-11 AS build

WORKDIR /app

COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline

# Copy source code
COPY src ./src

# Build WAR file
RUN mvn clean package -DskipTests


# STAGE 2: TOMCAT
FROM tomcat:9.0-jre11-temurin-jammy

# Remove default apps and create app user
RUN rm -rf /usr/local/tomcat/webapps/* \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --home-dir /usr/local/tomcat --shell /usr/sbin/nologin app \
    && mkdir -p /usr/local/tomcat/tmpFiles \
    && chown -R app:app /usr/local/tomcat

# Copy WAR file from Stage 1 to Stage 2
COPY --from=build --chown=app:app /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Java memory settings
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError -Djava.security.egd=file:/dev/./urandom"

# Run as non-root user
USER 10001

# Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
