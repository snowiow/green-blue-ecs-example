# build and test stage
FROM golang:alpine AS build-env
RUN apk --no-cache add build-base git gcc
ADD . /src
RUN cd /src && go test && go build -o goapp

# final stage
FROM alpine
WORKDIR /app
COPY --from=build-env /src/ /app/
EXPOSE 80
ENTRYPOINT ./goapp