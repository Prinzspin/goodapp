/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "deleteRule": "@request.auth.id = user || event.creator = @request.auth.id",
    "updateRule": "event.creator = @request.auth.id"
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_700663329")

  // update collection data
  unmarshal({
    "deleteRule": "@request.auth.id = user || @collection.events.creator = @request.auth.id",
    "updateRule": "@collection.events.creator = @request.auth.id"
  }, collection)

  return app.save(collection)
})
