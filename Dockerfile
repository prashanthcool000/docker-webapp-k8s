
# -------- Stage 1: Build the application --------
FROM maven:3.9-eclipse-temurin-11 AS build

WORKDIR /app

# Copy project files
COPY pom.xml .
COPY src ./src

# Build WAR file
RUN mvn clean package -DskipTests


# -------- Stage 2: Run the application --------
FROM tomcat:9.0-jre11-temurin-jammy AS runtime

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/* \
    && groupadd --system --gid 10001 app || true \
     && useradd  --system --uid 10001 --gid app -m -s / bin/bash app || true \
     && mkdir -p /usr/local/tomcat/tmpFiles \
     && chown -R app:app /usr/local/tomcat

# Copy WAR file from Stage 1
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
