%{
// Copyright 2016 Alex Shekhter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
package main

import (
    "fmt"
    _ "os"
    enc "encoding/xml"
    "bytes"
    "regexp"
    "sort"
)

type ElType int
const (
    ELEM ElType = iota
    PROP
    OTHER
)

type El struct {
    name    string
    value   string
    level   int
    elType  ElType
    isAfterProp bool
    childs  []*El
    col     int
    line    int
}

%}

%union {
    tok     string
    col     int
    line    int
    level   int
    el      *El
}

%token EQ OCB CCB WORD 

%nonassoc TO_ELEM
%right EQ OCB
%nonassoc WORD

%start RootElement

%%
RootElement
    : WORD OCB CCB                  { $$.el = addEl( $1.tok, $2.level, $1.line, $1.col, ELEM, "" ); }
    | WORD OCB SubElements CCB      { $$.el = addEl( $1.tok, $2.level, $1.line, $1.col, ELEM, "", $3.el ); 
                                      toXml( $$.el ); 
                                    }
    |                               {} 
    ;                                

SubElements
    : Element                       { $$.el = $1.el; }
    | Element SubElements           { $$.el = addEl( "", -1, -1, -1, OTHER, "", $1.el, $2.el ); }
    ;

Element
    : SubEl                         { $$.el = $1.el; 
                                      childsForParent = restoreChilds( $$.el, childsForParent ); 
                                    }
    | Property                      { $$.el = $1.el; }
    ;

SubEl
    : WORD OCB CCB                  { $$.el = addEl( $1.tok, $2.level, $1.line, $1.col, ELEM, "" ); }
    | WORD OCB SubElements CCB      { $$.el = addEl( $1.tok, $2.level, $1.line, $1.col, ELEM, "", $3.el ); }
    ;

Property
    : WORD EQ WordsList             { $$.el = addEl( $1.tok, -1, $1.line, $1.col, PROP, "", $3.el ); }
    ;

WordsList
    :                                   { $$.el = addEl( "", -1, -1, -1, OTHER, "" ); }
    | WordsList WORD                    { $$.el = addToValue( $1.el, $2.tok ); } 
    | WordsList Element %prec TO_ELEM   { $$.el = $1.el; $$.el.isAfterProp = true; childsForParent.store( $2.el ); }
    ;

%%

var (
    // childsForParent is the storage for the 
    // temporarily orphaned child elements
    childsForParent *Childs = new(Childs)
)

// addEl allocates new El and initializes it
func addEl( 
    name string, level int, line int, col int, 
    elType ElType, value string, childs ...*El ) (*El) {
    el := new( El )
    el.name     = name
    el.level    = level
    el.elType   = elType
    el.value    = value
    el.line     = line
    el.col      = col
    for _, ch := range childs {
        el.childs = append( el.childs, ch )
    }
    return el
}

// addToValue adds word to the property's value
func addToValue( el *El, value string ) *El {
    if el == nil {
        el = new(El)
    }
    if value != "" {
        if el.value != "" { 
            el.value += " " 
        }
        el.value += value
    }
    return el;
}

// Helper type
type childsArray []*El;

func (ca childsArray) Len() int { return len( ca ) }
func (ca childsArray) Swap( i, j int ) { 
    ca[ i ], ca[ j ] = ca[ j ], ca[ i ] 
}

// ByLocation struct will be used for sorting orphaned elements
// by location (line,col) in the input stream from lexer
type ByLocation struct{ childsArray }

func (s ByLocation) Less( i, j int ) bool {
    e1 := s.childsArray[ i ]
    e2 := s.childsArray[ j ]
    return (e1.line < e2.line || (e1.line == e2.line && e1.col < e2.col))
}

// Childs hold elements which cannot be added to the 
// parent immediately.
type Childs struct {
    childs childsArray
    lastSavedChild *El
}

// store stores orphaned element for the future
func (store *Childs) store( el *El ) {
    if store.lastSavedChild != el {
        store.childs = append( store.childs, el )
    }
}

// restoreChilds tries to find and associate orphaned elements 
// with the parent
func restoreChilds( parentEl *El, childs *Childs ) *Childs {
    newChilds := new(Childs)
    
    sort.Sort( ByLocation{childs.childs} )

    for _, el := range childs.childs {
        if el.elType == ELEM && parentEl.level >= el.level  {
            newChilds.childs = append( newChilds.childs, el )
        } else {
            parentEl.childs = append( parentEl.childs, el )
        }
    }
    if parentEl.isAfterProp {
        newChilds.childs = append( newChilds.childs, parentEl )
        newChilds.lastSavedChild = parentEl
    }
    return newChilds
}

// encode does XML encoding of the string
func encode( s string ) string {
    buf := new(bytes.Buffer)
    enc.EscapeText( buf, []byte( s ) )
    return buf.String()
}

// toXml prints XML
func toXml( ep *El ) {
    if ep == nil { return }
    re := regexp.MustCompile( `[\[\]]` )
    if ep.name != "" {
        fmt.Printf( "<%s>", encode( re.ReplaceAllString( ep.name, "_" ) ) )
    }
    var v string
    for _, ch := range ep.childs {
        
        if v == "" {
            v = ch.value
        } else {
            v += ch.value
        }

        toXml( ch )
    }
    if ep.name != "" {
        fmt.Printf( "%s</%s>", encode( v ), 
            encode( re.ReplaceAllString( ep.name, "_" ) ) )
    }
}
