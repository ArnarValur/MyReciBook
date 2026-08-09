# Cloud Run image — AOT-compiled, scratch runtime, cold-starts in ~100 ms.
FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline && \
    dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]
