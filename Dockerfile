
# ==============================
# STAGE 1: Download dependencies and build WAR
# ==============================

FROM maven:3.9-eclipse-temurin-11 AS build

# Set working directory
WORKDIR /app

# Copy Maven configuration
COPY pom.xml .

# Copy Java source code
COPY src ./src

# Build WAR file
RUN mvn clean package -DskipTests


# ==============================
# STAGE 2: Run WAR using Tomcat
# ==============================

FROM tomcat:9.0-jre11-temurin-jammy AS runtime

# Remove default Tomcat applications
RUN rm -rf /usr/local/tomcat/webapps/*

# Create user
RUN groupadd --system --gid 10001 user \
 && useradd --system --uid 10001 --gid user \
    --home-dir /usr/local/tomcat \
    --shell /usr/sbin/nologin user \
 && mkdir -p /usr/local/tomcat/tmpFiles \
 && chown -R user:user /usr/local/tomcat

# Copy WAR file from Stage 1 to Tomcat
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

# Run application using new user
USER user

# Tomcat port
EXPOSE 1234

# Start Tomcat
CMD ["catalina.sh", "run"]
