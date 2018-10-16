CREATE TABLE IF NOT EXISTS "${schema^}"."messages" (
  "id" SERIAL PRIMARY KEY,
  "pet_id" INTEGER NOT NULL REFERENCES "${schema^}"."pets",
  "message" TEXT NOT NULL,
  "created_at" TIMESTAMP NOT NULL,
  "created_block" BIGINT NOT NULL,
  "created_trx" TEXT NOT NULL,
  "created_eosacc" TEXT NOT NULL,
  "_dmx_created_at" TIMESTAMP DEFAULT current_timestamp NOT NULL
);
