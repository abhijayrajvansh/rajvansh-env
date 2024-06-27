echo 'services:
  db:
    image: postgres:latest
    container_name: docker-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres
    ports:
      - "5432:5432"
' >> docker-compose.yaml
echo ''
echo 'DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres"'
echo ''