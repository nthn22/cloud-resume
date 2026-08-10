# ============================================================
# DynamoDB table for the visitor counter.
# Mirrors what was built by hand: partition key "id" (String),
# on-demand billing, one starting item (id="count", visits=0).
# ============================================================

resource "aws_dynamodb_table" "visitor_count" {
  name         = "visitor-count-tf"   # different name from the manual one, so they don't collide
  billing_mode = "PAY_PER_REQUEST"    # matches "on-demand" capacity you chose manually
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"  # String
  }
}

# Seed the starting item, same as the manual "id=count, visits=0" you added by hand.
resource "aws_dynamodb_table_item" "starting_count" {
  table_name = aws_dynamodb_table.visitor_count.name
  hash_key   = aws_dynamodb_table.visitor_count.hash_key

  item = <<ITEM
{
  "id": {"S": "count"},
  "visits": {"N": "0"}
}
ITEM
}
