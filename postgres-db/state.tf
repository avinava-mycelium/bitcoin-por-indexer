terraform {
  backend "gcs" {
    bucket  = "backend-bucket-sdl"
    prefix  = "bitcoin/bitcoin-por-indexer-db.tfstate"
  }
}