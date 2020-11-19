(*
 * Open Dynamics Engine, Copyright (C) 2001,2002 Russell L. Smith.
 * All rights reserved.  Email: russ@q12.org   Web: www.q12.org
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of EITHER:
 *   (1) The GNU Lesser General Public License as published by the Free
 *       Software Foundation; either version 2.1 of the License, or (at
 *       your option) any later version. The text of the GNU Lesser
 *       General Public License is included with this library in the
 *       file LICENSE_LGPL.txt.
 *   (2) The BSD-style license that is included with this library in
 *       the file LICENSE_BSD.txt.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the files
 * LICENSE_LGPL.txt and LICENSE_BSD.txt for more details.
 *)

(* Basket ball demo.
   Serves as a test for the sphere vs trimesh collider
   By Bram Stolk. *)

(* Converted from C to OCaml by Florent Monnier *)

let usage() =
  print_endline "  Press the spacebar to reset the position of the ball.\n";
;;

open Ode.LowLevel
open Drawstuff

(* this is our world meshA *)


(* some constants *)

let radius = 0.14


let is_nan f = (Stdlib.compare nan f) = 0 ;;

(* this is called by dSpaceCollide when two objects in space are
   potentially colliding. *)

let rec nearCallback world contactgroup = fun o1 o2 ->

  if (dGeomIsSpace o1) || (dGeomIsSpace o2) then
  begin
    (* colliding a space with something *)
    dSpaceCollide2 o1 o2  (nearCallback  world contactgroup);
    (* Note we do not want to test intersections within a space, *)
    (* only between spaces. *)
    ()
  end else
  begin
    let contact_geom_arr = dCollide o1 o2 32 in
    ArrayLabels.iter contact_geom_arr ~f:(fun contact_geom ->
      (*
      (* checks for valid datas *)
      assert(dVALIDVEC3(contact_geom.cg_pos));
      assert(dVALIDVEC3(contact_geom.cg_normal));
      assert(not(is_nan(contact_geom.cg_depth)));
      *)
      let surf_param = {surf_param_zero with
        sp_mode = [`dContactSlip1; `dContactSoftERP;
                   `dContactSlip2; `dContactSoftCFM; `dContactApprox1;];
        sp_mu = 50.0; (* was: dInfinity *)
        sp_slip1 = 0.7;
        sp_slip2 = 0.7;
        sp_soft_erp = 0.96;
        sp_soft_cfm = 0.04;
      } in
      let contact = {
        c_surface = surf_param;
        c_geom = contact_geom;
        c_fdir1 = {x=0.; y=0.; z=0.; w=0.};
      } in
      let c = dJointCreateContact world (Some contactgroup) contact in
      dJointAttach c (dGeomGetBody contact_geom.cg_g1)
                     (dGeomGetBody contact_geom.cg_g2);
    );
  end;
;;



(* puts the ball at its initial position *)
let reset_ball sphbody =
  let sx=0.0 and sy=3.40 and sz=7.05 in
  let q = dQGetIdentity() in
  dBodySetPosition sphbody sx sy sz;
  dBodySetQuaternion sphbody q;
  dBodySetLinearVel sphbody 0. 0. 0.;
  dBodySetAngularVel sphbody 0. 0. 0.;
;;


(* called when a key pressed *)
let command sphbody = function
  | ' ' -> reset_ball sphbody;
  | _ -> ()
;;


(* simulation loop *)

let sim_step world space contactgroup = fun pause ->
  let simstep = 0.001 in (* 1ms simulation steps *)
  (*
  let dt = dsElapsedTime() in
  *)
  let dt = 0.01666 in

  let nrofsteps = truncate(ceil (dt /. simstep)) in
  (* Printf.eprintf "dt=%f, nr of steps = %d\n" dt nrofsteps; *)

  if not(pause) then
  for i=0 to pred nrofsteps do
    dSpaceCollide space (nearCallback world contactgroup);
    dWorldQuickStep world simstep;
    dJointGroupEmpty contactgroup;
  done;
;;


(* draw simulation scene *)

let sim_draw sphbody world_mesh
             world_indices world_vertices world_normals = fun () ->
  let color = (1.,0.2,0.) in
  let spos = dBodyGetPosition sphbody
  and srot = dBodyGetRotation sphbody in
  dsDrawSphere spos srot radius color;

  (* draw world trimesh *)
  let color = (0.4,0.8,0.2) in
  let pos = dGeomGetPosition world_mesh
  and rot = dGeomGetRotation world_mesh
  in
  dsDrawTriangles pos rot world_vertices  world_indices
                          (Some world_normals) color;
;;


(* main *)
let () =
  usage();
(* {{{ datas *)

  let world_normals = [|
    0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;-0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;0.;0.;-1.;
    0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;-0.;1.;0.;0.;1.;0.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;1.;0.;-0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;
    -1.;0.;0.;-1.;0.;0.;0.;-0.948064;0.318080;0.;-0.989482;0.144655;0.;-0.983494;0.180939;
    0.;-0.983494;0.180939;0.;-0.908999;0.416798;0.;-0.948064;0.318080;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;-1.;0.;-0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;-0.132460;
    0.991188;0.;0.264920;0.964270;0.;0.132460;0.991188;0.;0.132460;0.991188;0.;-0.264920;
    0.964270;0.;-0.132460;0.991188;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;
    -1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;-1.;0.;0.;-1.;0.;
    0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;-0.687592;-0.726097;
    -0.;-0.881727;-0.471761;0.;-0.687592;-0.726097;-0.;-0.881727;-0.471761;0.;-0.881727;
    -0.471761;0.;-0.687592;-0.726097;-0.;0.687592;-0.726097;0.;0.928375;-0.371644;0.;
    0.824321;-0.566123;0.;0.687592;-0.726097;0.;0.824321;-0.566123;0.;0.687592;-0.726097;
    0.;-0.881727;-0.471761;0.;-0.985594;-0.169128;0.;-0.985594;-0.169128;0.;-0.985594;
    -0.169128;0.;-0.881727;-0.471761;0.;-0.881727;-0.471761;0.;0.928375;-0.371644;0.;
    0.985594;-0.169128;0.;0.985594;-0.169128;0.;0.928375;-0.371644;0.;0.985594;-0.169128;
    0.;0.824321;-0.566123;0.;-0.870167;0.492758;0.;-0.870167;0.492758;0.;-0.870167;0.492758;
    0.;-0.870167;0.492758;0.;-0.870167;0.492758;0.;-0.870167;0.492758;0.;0.870167;0.492758;
    0.;0.870167;0.492758;0.;0.870167;0.492758;0.;0.870167;0.492758;0.;0.870167;0.492758;0.;
    0.870167;0.492758;-0.;-0.390313;0.920682;0.;-0.132460;0.991188;0.;-0.264920;0.964270;0.;
    -0.264920;0.964270;0.;-0.390313;0.920682;0.;-0.390313;0.920682;0.;0.390313;0.920682;0.;
    0.132460;0.991188;0.;0.264920;0.964270;0.;0.390313;0.920682;0.;0.264920;0.964270;0.;
    0.390313;0.920682;-0.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;
    0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;
    0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;
    -1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;
    0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;
    0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;
    -1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;0.;-1.;0.;
    0.;-1.;0.;0.;-1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.985594;0.169128;0.;0.824321;0.566123;0.;0.928375;
    0.371644;0.;0.928375;0.371644;0.;0.985594;0.169128;0.;0.985594;0.169128;0.;0.824321;
    0.566123;0.;0.687592;0.726097;0.;0.687592;0.726097;0.;0.687592;0.726097;0.;0.928375;
    0.371644;0.;0.824321;0.566123;0.;0.;1.;0.;-0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;
    0.;-0.687592;0.726097;0.;-0.687592;0.726097;0.;-0.881727;0.471761;0.;-0.881727;
    0.471761;0.;-0.881727;0.471761;0.;-0.687592;0.726097;0.;-0.881727;0.471761;0.;
    -0.985594;0.169128;0.;-0.985594;0.169128;0.;-0.985594;0.169128;0.;-0.881727;
    0.471761;0.;-0.881727;0.471761;0.;-0.870166;-0.492758;0.;-0.870166;-0.492758;0.;
    -0.870166;-0.492758;0.;-0.870166;-0.492758;0.;-0.870166;-0.492758;0.;-0.870166;
    -0.492758;0.;-0.390314;-0.920682;0.;-0.132460;-0.991188;0.;-0.264921;-0.964270;0.;
    -0.264921;-0.964270;0.;-0.390314;-0.920682;0.;-0.390314;-0.920682;0.;-0.132460;
    -0.991188;0.;0.264921;-0.964270;0.;0.132460;-0.991188;0.;0.132460;-0.991188;0.;
    -0.264921;-0.964270;0.;-0.132460;-0.991188;0.;0.264921;-0.964270;0.;0.390314;
    -0.920682;0.;0.390314;-0.920682;0.;0.390314;-0.920682;0.;0.132460;-0.991188;0.;
    0.264921;-0.964270;0.;0.870166;-0.492758;0.;0.870166;-0.492758;0.;0.870166;-0.492758;
    0.;0.870166;-0.492758;0.;0.870166;-0.492758;0.;0.870166;-0.492758;0.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;
    0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;-0.527606;0.849489;0.;-0.793893;0.608057;0.;
    -0.715135;0.698986;0.;-0.715135;0.698986;0.;-0.418249;0.908332;0.;-0.527606;0.849489;
    0.;-0.075284;0.997162;0.;-0.253577;0.967315;0.;-0.202069;0.979371;0.;-0.202069;0.979371;
    0.;-0.075284;0.997162;0.;-0.075284;0.997162;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;
    0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.160137;0.987095;0.;0.049305;0.998784;0.;0.049305;
    0.998784;0.;0.049305;0.998784;0.;0.221401;0.975183;0.;0.160137;0.987095;0.;0.696124;
    0.717921;0.;0.696124;0.717921;0.;0.433340;0.901230;0.;0.433340;0.901230;0.;0.433340;
    0.901230;0.;0.696124;0.717921;0.;0.696124;0.717921;0.;0.696124;0.717921;0.;0.838308;
    0.545197;0.;0.696124;0.717921;0.;0.872167;0.489208;0.;0.838308;0.545197;0.;-0.994126;
    0.108225;0.;-0.983494;0.180939;0.;-0.989482;0.144655;0.;-0.994126;0.108225;0.;-0.989482;
    0.144655;0.;-0.994126;0.108225;0.;-0.948064;0.318080;0.;-0.908999;0.416798;0.;-0.793893;
    0.608057;0.;-0.908999;0.416798;0.;-0.715135;0.698986;0.;-0.793893;0.608057;0.;-0.527606;
    0.849489;0.;-0.418249;0.908332;0.;-0.253577;0.967315;0.;-0.418249;0.908332;0.;-0.202069;
    0.979371;0.;-0.253577;0.967315;0.;-0.075284;0.997162;0.;-0.075284;0.997162;0.;0.;1.;0.;
    -0.075284;0.997162;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;
    1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.;1.;0.;0.049305;
    0.998784;0.;0.;1.;0.;0.049305;0.998784;0.;0.049305;0.998784;0.;0.160137;0.987095;0.;
    0.221401;0.975183;0.;0.433340;0.901230;0.;0.221401;0.975183;0.;0.433340;0.901230;0.;
    0.433340;0.901230;0.;0.902172;0.431376;0.;0.838308;0.545197;0.;0.872167;0.489208;0.;
    0.872167;0.489208;0.;0.902172;0.431376;0.;0.902172;0.431376;
  |]
  in

  let world_vertices = [|
    -4.;-4.;-0.1;  4.;-4.;-0.1;  4.;-4.;0.1;  -4.;-4.;-0.1;  4.;-4.;0.1;
    -4.;-4.;0.1;   4.;0.;0.1;    4.;-4.;-0.1; 4.;4.;-0.1;    4.;0.;0.1;
     4.;4.;-0.1;   4.;4.;0.1;    4.;0.;0.1;   4.;-4.;0.1;    4.;-4.;-0.1;
    -4.;-4.;-0.1; -4.;4.;-0.1;   4.;4.;-0.1; -4.;-4.;-0.1;   4.;4.;-0.1;
    4.;-4.;-0.1;0.066;-2.06;2.;0.066;-1.94;2.;-0.066;-2.06;2.;0.066;-1.94;
    2.;-0.066;-1.94;2.;-0.066;-2.06;2.;-4.;4.;0.1;4.;4.;0.1;4.;4.;-0.1;4.;
    4.;-0.1;-4.;4.;-0.1;-4.;4.;0.1;-4.;-4.;0.1;-4.;0.;0.1;-4.;-4.;-0.1;-4.;
    0.;0.1;-4.;4.;0.1;-4.;4.;-0.1;-4.;0.;0.1;-4.;4.;-0.1;-4.;-4.;-0.1;0.36;
    3.244444;1.466974;0.36;3.422222;2.266974;-0.36;3.422222;2.266974;-0.36;
    3.422222;2.266974;-0.36;3.244444;1.466974;0.36;3.244444;1.466974;4.;-4.;
    0.1;0.066;-2.06;0.1;-0.066;-2.06;0.1;-0.066;-2.06;0.1;-4.;-4.;0.1;4.;-4.;
    0.1;4.;0.;0.1;0.066;-1.94;0.1;4.;-4.;0.1;0.066;-1.94;0.1;0.066;-2.06;0.1;
    4.;-4.;0.1;-0.066;-1.94;0.1;0.066;-1.94;0.1;4.;0.;0.1;4.;0.;0.1;-4.;0.;
    0.1;-0.066;-1.94;0.1;-0.066;-2.06;0.1;-0.066;-1.94;0.1;-4.;0.;0.1;-4.;0.;
    0.1;-4.;-4.;0.1;-0.066;-2.06;0.1;0.066;-2.06;2.;-0.066;-2.06;2.;-0.066;
    -2.06;0.1;-0.066;-2.06;0.1;0.066;-2.06;0.1;0.066;-2.06;2.;0.066;-1.94;
    1.95;0.066;-1.94;2.;0.066;-2.06;2.;0.066;-2.06;2.;0.066;-2.06;0.1;0.066;
    -1.94;1.95;0.066;-2.06;0.1;0.066;-1.94;0.1;0.066;-1.94;1.95;-0.052853;
    -1.50639;2.;0.052853;-1.50639;2.;0.052853;-1.50639;1.95;0.052853;-1.50639;
    1.95;-0.052853;-1.50639;1.95;-0.052853;-1.50639;2.;-0.066;-2.06;0.1;
    -0.066;-2.06;2.;-0.066;-1.94;1.95;-0.066;-2.06;0.1;-0.066;-1.94;1.95;
    -0.066;-1.94;0.1;-0.066;-2.06;2.;-0.066;-1.94;2.;-0.066;-1.94;1.95;-0.066;
    -1.94;0.1;-0.066;-1.94;1.95;0.066;-1.94;1.95;-0.066;-1.94;0.1;0.066;-1.94;
    1.95;0.066;-1.94;0.1;-0.066;-1.94;1.95;-0.066;-1.84;1.95;0.066;-1.94;1.95;
    -0.066;-1.84;1.95;0.066;-1.84;1.95;0.066;-1.94;1.95;-0.066;-1.94;2.;
    -0.066;-1.84;2.;-0.066;-1.84;1.95;-0.066;-1.84;1.95;-0.066;-1.94;1.95;
    -0.066;-1.94;2.;0.066;-1.94;2.;0.066;-1.84;2.;-0.066;-1.94;2.;0.066;
    -1.84;2.;-0.066;-1.84;2.;-0.066;-1.94;2.;0.066;-1.94;1.95;0.066;-1.84;
    1.95;0.066;-1.84;2.;0.066;-1.94;1.95;0.066;-1.84;2.;0.066;-1.94;2.;
    -0.066;-1.84;2.;-0.1716;-1.74;2.;-0.066;-1.84;1.95;-0.1716;-1.74;2.;
    -0.1716;-1.74;1.95;-0.066;-1.84;1.95;0.066;-1.84;1.95;0.1716;-1.74;1.95;
    0.1716;-1.74;2.;0.066;-1.84;1.95;0.1716;-1.74;2.;0.066;-1.84;2.;-0.1716;
    -1.74;2.;-0.18876;-1.64;2.;-0.18876;-1.64;1.95;-0.18876;-1.64;1.95;
    -0.1716;-1.74;1.95;-0.1716;-1.74;2.;0.1716;-1.74;1.95;0.18876;-1.64;
    1.95;0.18876;-1.64;2.;0.1716;-1.74;1.95;0.18876;-1.64;2.;0.1716;-1.74;
    2.;-0.18876;-1.64;2.;-0.132132;-1.54;2.;-0.132132;-1.54;1.95;-0.132132;
    -1.54;1.95;-0.18876;-1.64;1.95;-0.18876;-1.64;2.;0.18876;-1.64;1.95;
    0.132132;-1.54;1.95;0.132132;-1.54;2.;0.18876;-1.64;1.95;0.132132;-1.54;
    2.;0.18876;-1.64;2.;-0.132132;-1.54;2.;-0.052853;-1.50639;2.;-0.052853;
    -1.50639;1.95;-0.052853;-1.50639;1.95;-0.132132;-1.54;1.95;-0.132132;
    -1.54;2.;0.132132;-1.54;1.95;0.052853;-1.50639;1.95;0.052853;-1.50639;
    2.;0.132132;-1.54;1.95;0.052853;-1.50639;2.;0.132132;-1.54;2.;0.18876;
    -1.64;1.95;0.173397;-1.642679;1.95;0.121808;-1.551577;1.95;0.121808;
    -1.551577;1.95;0.132132;-1.54;1.95;0.18876;-1.64;1.95;0.1716;-1.74;1.95;
    0.15795;-1.732697;1.95;0.173397;-1.642679;1.95;0.1716;-1.74;1.95;
    0.173397;-1.642679;1.95;0.18876;-1.64;1.95;0.1716;-1.74;1.95;0.066;
    -1.84;1.95;0.060149;-1.825311;1.95;0.1716;-1.74;1.95;0.060149;-1.825311;
    1.95;0.15795;-1.732697;1.95;-0.066;-1.84;1.95;-0.060149;-1.825311;1.95;
    0.066;-1.84;1.95;-0.060149;-1.825311;1.95;0.060149;-1.825311;1.95;0.066;
    -1.84;1.95;-0.1716;-1.74;1.95;-0.15795;-1.732697;1.95;-0.060149;
    -1.825311;1.95;-0.1716;-1.74;1.95;-0.060149;-1.825311;1.95;-0.066;-1.84;
    1.95;-0.173397;-1.642679;1.95;-0.15795;-1.732697;1.95;-0.1716;-1.74;
    1.95;-0.1716;-1.74;1.95;-0.18876;-1.64;1.95;-0.173397;-1.642679;1.95;
    -0.121808;-1.551577;1.95;-0.173397;-1.642679;1.95;-0.18876;-1.64;1.95;
    -0.18876;-1.64;1.95;-0.132132;-1.54;1.95;-0.121808;-1.551577;1.95;
    -0.052853;-1.50639;1.95;-0.049868;-1.521079;1.95;-0.121808;-1.551577;
    1.95;-0.052853;-1.50639;1.95;-0.121808;-1.551577;1.95;-0.132132;-1.54;
    1.95;0.049868;-1.521079;1.95;-0.049868;-1.521079;1.95;-0.052853;
    -1.50639;1.95;-0.052853;-1.50639;1.95;0.052853;-1.50639;1.95;0.049868;
    -1.521079;1.95;0.052853;-1.50639;1.95;0.132132;-1.54;1.95;0.121808;
    -1.551577;1.95;0.052853;-1.50639;1.95;0.121808;-1.551577;1.95;0.049868;
    -1.521079;1.95;-0.18876;-1.64;2.;-0.173397;-1.642679;2.;-0.121808;
    -1.551577;2.;-0.121808;-1.551577;2.;-0.132132;-1.54;2.;-0.18876;-1.64;
    2.;-0.1716;-1.74;2.;-0.15795;-1.732697;2.;-0.173397;-1.642679;2.;
    -0.173397;-1.642679;2.;-0.18876;-1.64;2.;-0.1716;-1.74;2.;-0.066;-1.84;
    2.;-0.060149;-1.825311;2.;-0.1716;-1.74;2.;-0.060149;-1.825311;2.;
    -0.15795;-1.732697;2.;-0.1716;-1.74;2.;0.066;-1.84;2.;0.060149;
    -1.825311;2.;-0.066;-1.84;2.;0.060149;-1.825311;2.;-0.060149;-1.825311;
    2.;-0.066;-1.84;2.;0.1716;-1.74;2.;0.15795;-1.732697;2.;0.060149;
    -1.825311;2.;0.1716;-1.74;2.;0.060149;-1.825311;2.;0.066;-1.84;2.;
    0.173397;-1.642679;2.;0.15795;-1.732697;2.;0.1716;-1.74;2.;0.1716;-1.74;
    2.;0.18876;-1.64;2.;0.173397;-1.642679;2.;0.121808;-1.551577;2.;
    0.173397;-1.642679;2.;0.18876;-1.64;2.;0.18876;-1.64;2.;0.132132;-1.54;
    2.;0.121808;-1.551577;2.;0.052853;-1.50639;2.;0.049868;-1.521079;2.;
    0.121808;-1.551577;2.;0.052853;-1.50639;2.;0.121808;-1.551577;2.;
    0.132132;-1.54;2.;-0.049868;-1.521079;2.;0.049868;-1.521079;2.;0.052853;
    -1.50639;2.;0.052853;-1.50639;2.;-0.052853;-1.50639;2.;-0.049868;
    -1.521079;2.;-0.121808;-1.551577;2.;-0.049868;-1.521079;2.;-0.052853;
    -1.50639;2.;-0.052853;-1.50639;2.;-0.132132;-1.54;2.;-0.121808;
    -1.551577;2.;-0.173397;-1.642679;2.;-0.15795;-1.732697;2.;-0.15795;
    -1.732697;1.95;-0.15795;-1.732697;1.95;-0.173397;-1.642679;1.95;
    -0.173397;-1.642679;2.;-0.15795;-1.732697;2.;-0.060149;-1.825311;2.;
    -0.060149;-1.825311;1.95;-0.060149;-1.825311;1.95;-0.15795;-1.732697;
    1.95;-0.15795;-1.732697;2.;-0.060149;-1.825311;2.;0.060149;-1.825311;2.;
    0.060149;-1.825311;1.95;0.060149;-1.825311;1.95;-0.060149;-1.825311;
    1.95;-0.060149;-1.825311;2.;0.060149;-1.825311;1.95;0.060149;-1.825311;
    2.;0.15795;-1.732697;2.;0.15795;-1.732697;2.;0.15795;-1.732697;1.95;
    0.060149;-1.825311;1.95;0.15795;-1.732697;2.;0.173397;-1.642679;2.;
    0.173397;-1.642679;1.95;0.173397;-1.642679;1.95;0.15795;-1.732697;1.95;
    0.15795;-1.732697;2.;0.173397;-1.642679;2.;0.121808;-1.551577;2.;
    0.121808;-1.551577;1.95;0.121808;-1.551577;1.95;0.173397;-1.642679;1.95;
    0.173397;-1.642679;2.;0.121808;-1.551577;2.;0.049868;-1.521079;2.;
    0.049868;-1.521079;1.95;0.049868;-1.521079;1.95;0.121808;-1.551577;1.95;
    0.121808;-1.551577;2.;0.049868;-1.521079;2.;-0.049868;-1.521079;2.;
    -0.049868;-1.521079;1.95;-0.049868;-1.521079;1.95;0.049868;-1.521079;
    1.95;0.049868;-1.521079;2.;-0.049868;-1.521079;2.;-0.121808;-1.551577;
    2.;-0.121808;-1.551577;1.95;-0.121808;-1.551577;1.95;-0.049868;-1.521079;1.95;
    -0.049868;-1.521079;2.;-0.121808;-1.551577;2.;-0.173397;-1.642679;2.;-0.173397;
    -1.642679;1.95;-0.173397;-1.642679;1.95;-0.121808;-1.551577;1.95;-0.121808;
    -1.551577;2.;-0.36;3.6;0.1;0.36;3.6;0.1;4.;4.;0.1;4.;4.;0.1;-4.;4.;0.1;-0.36;
    3.6;0.1;-0.36;0.4;0.1;-0.36;3.6;0.1;-4.;4.;0.1;-4.;4.;0.1;-4.;0.;0.1;-0.36;0.4;
    0.1;4.;0.;0.1;0.36;0.4;0.1;-0.36;0.4;0.1;-0.36;0.4;0.1;-4.;0.;0.1;4.;0.;0.1;4.;
    4.;0.1;0.36;3.6;0.1;4.;0.;0.1;0.36;3.6;0.1;0.36;0.4;0.1;4.;0.;0.1;0.36;2.888889;
    1.023752;0.36;3.066667;1.166974;-0.36;3.066667;1.166974;-0.36;3.066667;1.166974;
    -0.36;2.888889;1.023752;0.36;2.888889;1.023752;0.36;2.533333;0.939976;0.36;
    2.711111;0.966974;-0.36;2.711111;0.966974;-0.36;2.711111;0.966974;-0.36;2.533333;
    0.939976;0.36;2.533333;0.939976;-0.36;2.177778;0.939976;0.36;2.177778;0.939976;
    0.36;2.355556;0.939976;0.36;2.355556;0.939976;-0.36;2.355556;0.939976;-0.36;
    2.177778;0.939976;-0.36;1.822222;0.939976;0.36;1.822222;0.939976;0.36;2.;0.939976;
    0.36;2.;0.939976;-0.36;2.;0.939976;-0.36;1.822222;0.939976;-0.36;1.466667;0.939976;
    0.36;1.466667;0.939976;0.36;1.644444;0.939976;0.36;1.644444;0.939976;-0.36;
    1.644444;0.939976;-0.36;1.466667;0.939976;0.36;1.111111;0.957571;0.36;1.288889;
    0.939976;-0.36;1.288889;0.939976;-0.36;1.288889;0.939976;-0.36;1.111111;0.957571;
    0.36;1.111111;0.957571;-0.36;0.755556;1.134246;0.36;0.755556;1.134246;0.36;
    0.933333;1.009739;0.36;0.933333;1.009739;-0.36;0.933333;1.009739;-0.36;0.755556;
    1.134246;0.36;0.755556;1.134246;-0.36;0.755556;1.134246;0.36;0.577778;1.37213;
    -0.36;0.755556;1.134246;-0.36;0.577778;1.37213;0.36;0.577778;1.37213;-0.36;3.6;
    3.9;-0.36;3.422222;2.266974;0.36;3.422222;2.266974;-0.36;3.6;3.9;0.36;3.422222;
    2.266974;0.36;3.6;3.9;0.36;3.244444;1.466974;-0.36;3.244444;1.466974;0.36;3.066667;
    1.166974;-0.36;3.244444;1.466974;-0.36;3.066667;1.166974;0.36;3.066667;1.166974;
    0.36;2.888889;1.023752;-0.36;2.888889;1.023752;0.36;2.711111;0.966974;-0.36;2.888889;
    1.023752;-0.36;2.711111;0.966974;0.36;2.711111;0.966974;0.36;2.533333;0.939976;
    -0.36;2.533333;0.939976;-0.36;2.355556;0.939976;0.36;2.533333;0.939976;-0.36;
    2.355556;0.939976;0.36;2.355556;0.939976;0.36;2.177778;0.939976;-0.36;2.177778;
    0.939976;-0.36;2.;0.939976;0.36;2.177778;0.939976;-0.36;2.;0.939976;0.36;2.;
    0.939976;0.36;1.822222;0.939976;-0.36;1.822222;0.939976;-0.36;1.644444;0.939976;
    0.36;1.822222;0.939976;-0.36;1.644444;0.939976;0.36;1.644444;0.939976;0.36;
    1.466667;0.939976;-0.36;1.466667;0.939976;-0.36;1.288889;0.939976;0.36;1.466667;
    0.939976;-0.36;1.288889;0.939976;0.36;1.288889;0.939976;0.36;1.111111;0.957571;
    -0.36;1.111111;0.957571;0.36;0.933333;1.009739;-0.36;1.111111;0.957571;-0.36;
    0.933333;1.009739;0.36;0.933333;1.009739;0.36;0.4;1.743932;0.36;0.577778;1.37213;
    -0.36;0.577778;1.37213;-0.36;0.577778;1.37213;-0.36;0.4;1.743932;0.36;0.4;1.743932;
  |]
  in

  let world_indices = [|
    0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;
    27;28;29;30;31;32;33;34;35;36;37;38;39;40;41;42;43;44;45;46;47;48;49;50;
    51;52;53;54;55;56;57;58;59;60;61;62;63;64;65;66;67;68;69;70;71;72;73;74;
    75;76;77;78;79;80;81;82;83;84;85;86;87;88;89;90;91;92;93;94;95;96;97;98;
    99;100;101;102;103;104;105;106;107;108;109;110;111;112;113;114;115;116;
    117;118;119;120;121;122;123;124;125;126;127;128;129;130;131;132;133;134;
    135;136;137;138;139;140;141;142;143;144;145;146;147;148;149;150;151;152;
    153;154;155;156;157;158;159;160;161;162;163;164;165;166;167;168;169;170;
    171;172;173;174;175;176;177;178;179;180;181;182;183;184;185;186;187;188;
    189;190;191;192;193;194;195;196;197;198;199;200;201;202;203;204;205;206;
    207;208;209;210;211;212;213;214;215;216;217;218;219;220;221;222;223;224;
    225;226;227;228;229;230;231;232;233;234;235;236;237;238;239;240;241;242;
    243;244;245;246;247;248;249;250;251;252;253;254;255;256;257;258;259;260;
    261;262;263;264;265;266;267;268;269;270;271;272;273;274;275;276;277;278;
    279;280;281;282;283;284;285;286;287;288;289;290;291;292;293;294;295;296;
    297;298;299;300;301;302;303;304;305;306;307;308;309;310;311;312;313;314;
    315;316;317;318;319;320;321;322;323;324;325;326;327;328;329;330;331;332;
    333;334;335;336;337;338;339;340;341;342;343;344;345;346;347;348;349;350;
    351;352;353;354;355;356;357;358;359;360;361;362;363;364;365;366;367;368;
    369;370;371;372;373;374;375;376;377;378;379;380;381;382;383;384;385;386;
    387;388;389;390;391;392;393;394;395;396;397;398;399;400;401;402;403;404;
    405;406;407;408;409;410;411;412;413;414;415;416;417;418;419;420;421;422;
    423;424;425;426;427;428;429;430;431;432;433;434;435;436;437;438;439;440;
    441;442;443;444;445;446;447;448;449;450;451;452;453;454;455;456;457;458;
    459;460;461;462;463;464;465;466;467;468;469;470;471;472;473;474;475;476;
    477;478;479;480;481;482;483;484;485;
  |]
  in

  (* }}} *)

  (*
  Printf.printf "world_normals(%d) world_vertices(%d) world_indices(%d)\n%!"
      (Array.length world_normals)
      (Array.length world_vertices)
      (Array.length world_indices);
  *)

  (* create world *)
  dInitODE();
  let world = dWorldCreate()
  and space = dHashSpaceCreate None
  and contactgroup = dJointGroupCreate() in

  dWorldSetGravity world 0. 0. (-9.8);
  dWorldSetQuickStepNumIterations world 64;

  (* dynamics and collision objects *)

  (* Create a static world using a triangle mesh that we can collide with. *)
  let data = dGeomTriMeshDataCreate() in
  dGeomTriMeshDataBuild data world_vertices world_indices;
  let world_mesh = dCreateTriMesh (Some space) data () in

  dGeomTriMeshEnableTC world_mesh SphereClass false;
  dGeomTriMeshEnableTC world_mesh BoxClass false;
  dGeomSetPosition world_mesh 0. 0. 0.5;

  let r = dRGetIdentity() in
  dGeomSetRotation world_mesh r;

  let m = dMassCreate() in

  (* create the ball *)
  let sphbody = dBodyCreate world in
  dMassSetSphere m 1. radius;
  dBodySetMass sphbody m;
  let sphgeom = dCreateSphere None radius in
  dGeomSetBody sphgeom (Some sphbody);
  reset_ball sphbody;
  dSpaceAdd space sphgeom;

  (* destroy all the objects when leaving the simulation *)
  let exit_func() =
    dBodyDestroy sphbody;

    dGeomDestroy sphgeom;
    dGeomDestroy world_mesh;

    dGeomTriMeshDataDestroy data;

    dJointGroupEmpty contactgroup;
    dJointGroupDestroy contactgroup;

    dSpaceDestroy space;
    dWorldDestroy world;

    dCloseODE();
  in

  (* run simulation *)
  begin
    (* set initial viewpoint *)
    let pos = (7.6, 5.5, -4.4)
    and angles = (98.6, 233.4) in

    (* call sim_step every N milliseconds *)
    let timer_msecs = 10 in

    (* simulation params (for the drawstuff lib) *)
    let dsd =
      ( (pos, angles, timer_msecs, world),
        (sim_draw sphbody world_mesh world_indices world_vertices world_normals),
        (sim_step world space contactgroup),
        (command sphbody),
        (exit_func)
      )
    in
    dsSimulationLoop 480 360 dsd;
  end;
;;

(* vim: sw=2 sts=2 ts=2 et fdm=marker
 *)
