import{r as c,g as m}from"./index-D8qnCZPB.js";function d(o,r){for(var s=0;s<r.length;s++){const e=r[s];if(typeof e!="string"&&!Array.isArray(e)){for(const t in e)if(t!=="default"&&!(t in o)){const n=Object.getOwnPropertyDescriptor(e,t);n&&Object.defineProperty(o,t,n.get?n:{enumerable:!0,get:()=>e[t]})}}}return Object.freeze(Object.defineProperty(o,Symbol.toStringTag,{value:"Module"}))}var p={exports:{}},f={};/**
 * @license React
 * react-jsx-runtime.production.min.js
 *
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */var x=c,y=Symbol.for("react.element"),j=Symbol.for("react.fragment"),g=Object.prototype.hasOwnProperty,O=x.__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED.ReactCurrentOwner,b={key:!0,ref:!0,__self:!0,__source:!0};function _(o,r,s){var e,t={},n=null,a=null;s!==void 0&&(n=""+s),r.key!==void 0&&(n=""+r.key),r.ref!==void 0&&(a=r.ref);for(e in r)g.call(r,e)&&!b.hasOwnProperty(e)&&(t[e]=r[e]);if(o&&o.defaultProps)for(e in r=o.defaultProps,r)t[e]===void 0&&(t[e]=r[e]);return{$$typeof:y,type:o,key:n,ref:a,props:t,_owner:O.current}}f.Fragment=j;f.jsx=_;f.jsxs=_;p.exports=f;var i=p.exports;const v=m(i),l=d({__proto__:null,default:v},[i]),u=Reflect.get(l,"default")??l,R=u.Fragment,P=u.jsx,S=u.jsxs;export{R as Fragment,u as default,P as jsx,S as jsxs};
