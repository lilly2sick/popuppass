import { admin } from "../_shared/auth.ts";
import { createHandler } from "./handler.ts";

Deno.serve(createHandler({ db: admin() }));
