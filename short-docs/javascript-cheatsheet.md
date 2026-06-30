# JavaScript — DevOps Cheatsheet

## Types & Coercion

```js
typeof "hello"        // "string"
typeof 42             // "number"
typeof true           // "boolean"
typeof {}             // "object"
typeof []             // "object" (use Array.isArray)
typeof null           // "object" (🤡)
typeof undefined      // "undefined"
typeof Symbol()       // "symbol"

// Truthy / Falsy
// falsy: false, 0, "", null, undefined, NaN
// everything else is truthy
```

## Variables

```js
const x = 1          // block-scoped, can't reassign
let y = 2            // block-scoped, can reassign
var z = 3            // function-scoped, hoisted (avoid)
```

## Strings

```js
`hello ${name}`                      // template literal
str.length                            // length
str.slice(0, 5)                       // substring
str.split(",")                        // split
str.includes("foo")                   // contains
str.startsWith("x"), str.endsWith("y")
str.replace("old", "new")             // first
str.replaceAll("old", "new")          // all
str.trim(), str.toUpperCase(), str.toLowerCase()
```

## Arrays

```js
arr.push(x), arr.pop()                // end
arr.unshift(x), arr.shift()           // front
arr.includes(x)                       // contains
arr.find(fn), arr.findIndex(fn)       // first match
arr.filter(fn)                        // keep matches
arr.map(fn)                           // transform
arr.reduce((acc, x) => acc + x, 0)    // aggregate
arr.some(fn), arr.every(fn)           // any / all
arr.sort()                            // in-place (careful: sorts as strings)
arr.sort((a, b) => a - b)             // numeric
arr.slice(begin, end)                 // copy segment
arr.splice(idx, count, ...items)      // remove/replace in-place
[...arr1, ...arr2]                    // spread concat
```

## Objects

```js
const obj = { a: 1, b: 2 }
Object.keys(obj)                      // ["a", "b"]
Object.values(obj)                    // [1, 2]
Object.entries(obj)                   // [["a",1], ["b",2]]
{ ...obj, c: 3 }                     // spread merge
Object.assign({}, obj, { c: 3 })     // merge
delete obj.a                          // remove key
"a" in obj                            // check key exists
obj?.a?.b ?? "default"               // optional chaining + nullish coalescing
```

## Functions

```js
const fn = (a, b) => a + b            // arrow
const fn = function(a, b) { return a + b }
function fn(a, b = 10) { ... }        // default param
const fn = (...args) => args          // rest params
```

## Destructuring

```js
const [a, b] = arr
const { name, age } = obj
const { name: alias } = obj           // rename

function f({ x, y }) { ... }          // param destructuring
```

## Promises & Async

```js
fetch(url)
  .then(r => r.json())
  .then(d => console.log(d))
  .catch(err => console.error(err))

const res = await fetch(url)
const data = await res.json()

const [a, b] = await Promise.all([p1, p2])
const r = await Promise.race([p1, p2])
```

## Error Handling

```js
try {
  const r = await risky()
} catch (err) {
  console.error(err.message)
  process.exit(1)
} finally {
  cleanup()
}
```

## Modules

```js
// export
export const x = 1
export default fn

// import
import fn, { x } from "./lib.js"
import * as lib from "./lib.js"
```

## Process & Env (Node.js)

```js
process.env.NODE_ENV                  // env var
process.argv                          // CLI args
process.cwd()                         // current dir
process.exit(0)                       // exit success
process.exit(1)                       // exit error
process.on("uncaughtException", fn)   // global error
process.on("SIGTERM", fn)             // graceful shutdown
process.pid                           // PID
```

## File System (Node.js)

```js
import fs from "fs/promises"

await fs.readFile("file.txt", "utf-8")
await fs.writeFile("file.txt", "data")
await fs.appendFile("file.txt", "more")
await fs.mkdir("dir", { recursive: true })
await fs.rm("dir", { recursive: true })
await fs.cp("src", "dst", { recursive: true })
await fs.stat("file.txt")             // size, mtime, isFile(), isDirectory()
await fs.readdir("dir")               // files in dir
fs.existsSync("path")                 // sync check
```

## JSON & YAML

```js
JSON.parse(str)
JSON.stringify(obj, null, 2)

import yaml from "js-yaml"
yaml.load(str)
yaml.dump(obj)
```

## HTTP (Node.js)

```js
import fetch from "node-fetch"  // built-in from Node 18+

const r = await fetch(url, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ key: "val" })
})
r.status, r.ok
const json = await r.json()
const text = await r.text()
```

## Common Patterns

```js
// default with nullish coalescing
const port = process.env.PORT ?? 3000

// safe access
const city = user?.address?.city ?? "unknown"

// unique array
[...new Set([1, 2, 2, 3])]

// sleep
const sleep = ms => new Promise(r => setTimeout(r, ms))
await sleep(1000)

// retry
const retry = async (fn, n = 3) => {
  for (let i = 0; i < n; i++) {
    try { return await fn() } catch (e) { if (i === n-1) throw e }
  }
}

// flatten
arr.flat(Infinity)

// group by
Object.groupBy(arr, x => x.category)  // ES2024
```

## One-liners

```js
// read JSON config
JSON.parse(fs.readFileSync("./config.json"))

// parse CLI args
process.argv.slice(2).reduce((acc, a, i) => (i%2 ? (acc[process.argv[i+1]] = a) : acc), {})

// env var fallback
process.env.HOME || "/tmp"

// watch directory
fs.watch(dir, (event, file) => console.log(event, file))
```
