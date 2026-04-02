/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_728114816")

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
  const collection = app.findCollectionByNameOrId("pbc_728114816")

  // update collection data
  unmarshal({
    "createRule": "",
    "deleteRule": "",
    "listRule": "@collection.event_members.event = event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\"",
    "updateRule": "",
    "viewRule": "@collection.event_members.event = event && @collection.event_members.user = @request.auth.id && @collection.event_members.status = \"accepted\""
  }, collection)

  return app.save(collection)
})
