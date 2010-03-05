{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
{ DSFreeFrameWrapper                                               }
{       a filter for using freeframe (http://www.freeframe.org)    }
{       plugins in a directshow graph                              }
{                                                                  }
{                                                                  }
{ author: joreg@joreg.ath.cx                                       }
{         http://joreg.ath.cx                                      }
{                                                                  }
{ based on: FreeFrame Delphi interface definitions by              }
{           Russell Blakeborough - boblists@brightonart.org        }
{                                                                  }
{           directshow baseclass translations for delphi           }
{           provided by http://www.progdigy.com                    }
{           (need to be included in the searchpath if you          }
{           want to compile this filter)                           }
{                                                                  }
{                                                                  }
{ The contents of this file are used with permission, subject to   }
{ the Mozilla Public License Version 1.1 (the "License"); you may  }
{ not use this file except in compliance with the License. You may }
{ obtain a copy of the License at                                  }
{ http://www.mozilla.org/MPL/MPL-1.1.html                          }
{                                                                  }
{ Software distributed under the License is distributed on an      }
{ "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or   }
{ implied. See the License for the specific language governing     }
{ rights and limitations under the License.                        }
{                                                                  }
{ 12-12-2003: initial release                                      }
{ 25-12-2003: added propertypage, improved stability               }
{ 13-02-2004: removed extra pinclasses for easier handling         }
{             of formatchanges, now also deals with dv-streams     }
{~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~}


library DSFreeFrameWrapper;

uses
  BaseClass,
  main in 'main.pas',
  PropPage in 'PropPage.pas' {PropertyPage},
  psvFolderDialog in 'psvFolderDialog.pas';

{$E ax}

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer;

begin

end.

