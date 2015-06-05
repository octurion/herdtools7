(*********************************************************************)
(*                       DIY                                         *)
(*                                                                   *)
(*               Luc Maranget, INRIA Paris-Rocquencourt, France.     *)
(*                                                                   *)
(*  Copyright 2015 Institut National de Recherche en Informatique et *)
(*  en Automatique and the authors. All rights reserved.             *)
(*  This file is distributed  under the terms of the Lesser GNU      *)
(*  General Public License.                                          *)
(*********************************************************************)

open Printf

exception Over

module Action = struct
  type t = Check | Rewrite

  let tags = ["check"; "rewrite";]

  let parse s = match String.lowercase s with
  | "check" -> Some Check
  | "rewrite" -> Some Rewrite
  | _ -> None

  let pp = function
    | Check -> "check"
    | Rewrite -> "rewrite"
end

module Top
    (Opt:
       sig
         val verbose : int
         val action : Action.t
       end) =
  struct
    open Action

    module T = struct
      type t = 
        { tname : string ;
          hash : string option; } 
    end

    module Make(A:ArchBase.S) = struct

      let zyva name parsed =
	let tname = name.Name.name in
	let hash = MiscParser.get_hash parsed in
	if Opt.verbose > 1
	then eprintf "%s %s\n"
			   tname
			    (match hash with 
			    | None -> "none" 
			    | Some h -> h);
        { T.tname = tname ;
          hash = hash; }
    end

    module Z = ToolParse.Top(T)(Make)

    type name = {fname:string; tname:string;}

    let do_test name k =
      try
        let {T.tname = tname;
             hash = h; } = Z.from_file name in
        let h = Misc.as_some h in
        let old = StringMap.safe_find h tname k in
        if old <> h then begin
          eprintf "Different hashes for test %s" tname ;
          raise Over
        end ;
        StringMap.add tname h k
      with
      | Misc.Exit -> k
      | Misc.Fatal msg ->
          Warn.warn_always "%a %s" Pos.pp_pos0 name msg ;
          k
      | e ->
          eprintf "\nFatal: %a Adios\n" Pos.pp_pos0 name ;
          raise e

    let zyva tests logs =
      let env = Misc.fold_argv do_test tests StringMap.empty in
      let module Lex =
        LexHashLog.Make
          (struct
            let verbose = Opt.verbose > 0
            let env = env
          end) in
      let action = match Opt.action with
      | Check -> Lex.check
      | Rewrite -> Lex.rewrite in
      let action =
        if Opt.verbose > 0 then
          fun fname ->
            eprintf "reading %s\n%!" fname ;
            action fname
        else action in
      List.iter action logs
  end



let verbose = ref 0
let action = ref Action.Check
let tests = ref [] 
let arg = ref []

let prog =
  if Array.length Sys.argv > 0 then Sys.argv.(0)
  else "mhash"

let () =
  Arg.parse
    [
     "-v",Arg.Unit (fun () -> incr verbose), " be verbose";
     "-select", Arg.String (fun s -> tests := !tests @ [s]),
     "<name> extract hashes from those tests";
     begin let module P = ParseTag.Make(Action) in
     P.parse "-action" action "action performed" end ;
    ]
    (fun s -> arg := !arg @ [s])
    (sprintf "Usage: %s [options]* [log]*" prog)

let tests = !tests
let logs = !arg
module X =
  Top
    (struct
      let verbose = !verbose
      let action = !action
    end)

let () = X.zyva tests logs
