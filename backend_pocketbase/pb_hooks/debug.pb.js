// debug.pb.js
try {
    for (var key in this) {
        if (key.indexOf("Record") !== -1 || key.indexOf("on") === 0) {
            console.log("Global key: " + key);
        }
    }
} catch (e) {
    console.log("Error listing globals: " + e);
}
