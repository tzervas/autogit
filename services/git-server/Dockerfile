FROM alpine:3.19

# Install basic dependencies
RUN apk add --no-cache \
    git \
    openssh \
    bash

# Create service user
RUN adduser -D -h /app git

WORKDIR /app

EXPOSE 22 3000

CMD ["sh", "-c", "echo 'Git server placeholder - implement as needed'"]
