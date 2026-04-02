/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2605467279")

  // update collection data
  unmarshal({
    "listRule": "@collection.conversations.id = conversation && @collection.event_members.event = @collection.conversations.event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\"",
    "viewRule": "@collection.conversations.id = conversation && @collection.event_members.event = @collection.conversations.event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2605467279")

  // update collection data
  unmarshal({
    "listRule": "@request.auth.id != \"\"",
    "viewRule": "@request.auth.id != \"\""
  }, collection)

  return app.save(collection)
})
