GREEN='\033[0;32m'
RESET='\033[0m'
alias greentick='echo -n ${GREEN}✔ ${RESET}'

echo '
services: 
  postgres:
    image: postgres
    container_name: docker-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_DB: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - 5432:5432
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
' >> docker-compose.yaml

echo '> Writing docker-compose.yaml file...'
greentick; echo 'Postgres service added to docker-compose.yaml.\n'
echo 'DATABASE_URL="postgresql://postgres:postgres@localhost:5432/postgres?schema=public"'
