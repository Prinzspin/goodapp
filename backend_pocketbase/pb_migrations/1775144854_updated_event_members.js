/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.auth.id != \"\"",
    "deleteRule": "@request.auth.id != \"\"",
    "updateRule": "@request.auth.id != \"\""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "createRule": "@request.body.user = @request.auth.id",
    "deleteRule": "@request.auth.id = user || event.creator = @request.auth.id",
    "updateRule": "event.creator = @request.auth.id"
  }, collection)

  return app.save(collection)
})
