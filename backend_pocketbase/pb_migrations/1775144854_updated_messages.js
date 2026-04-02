/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_2605467279")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\"",
    "deleteRule": "@request.auth.id != \"\"",
    "listRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id != \"\"",
    "viewRule": "@request.auth.id != \"\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_2605467279")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\" && @request.auth.id = author",
    "deleteRule": "author = @request.auth.id",
    "listRule": "@collection.conversations.id = conversation && @collection.event_members.event = @collection.conversations.event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\"",
    "updateRule": null,
    "viewRule": "@collection.conversations.id = conversation && @collection.event_members.event = @collection.conversations.event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\""
  }, collection)

  return app.save(collection)
})
