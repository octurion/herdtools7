%{
(****************************************************************************)
(*                           the diy toolsuite                              *)
(*                                                                          *)
(* Jade Alglave, University College London, UK.                             *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                          *)
(*                                                                          *)
(* Copyright 2019-present Institut National de Recherche en Informatique et *)
(* en Automatique and the authors. All rights reserved.                     *)
(*                                                                          *)
(* This software is governed by the CeCILL-B license under French law and   *)
(* abiding by the rules of distribution of free software. You can use,      *)
(* modify and/ or redistribute the software under the terms of the CeCILL-B *)
(* license as circulated by CEA, CNRS and INRIA at the following URL        *)
(* "http://www.cecill.info". We also give a copy in LICENSE.txt.            *)
(****************************************************************************)
%}

%token <int> PROCFH

%%

proc_annot:
| COLON os=separated_list(COMMA,NAME) { os }

proc_annotated:
| p=PROCFH os=option(proc_annot) { p,os,MiscParser.FaultHandler }
| p=PROC os=option(proc_annot) { p,os,MiscParser.Main }

%public proc_list:
| separated_nonempty_list(PIPE,proc_annotated) SEMI { $1 }
