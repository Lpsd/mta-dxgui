> Note: This framework is currently unstable and in development. Every piece of code is subject to change so some functions may be changed completely or may not work at all in the future. Please take this into consideration when using this framework in your projects.

# DX-GUI (A framework for MTA)

DX-GUI allows scripters to build beautiful GUI with just a few lines of code.

My aim is to make this framework be faster and more flexible than DGS by splitting everything up in separate modules which allows us to re-use code and also makes it easier to update the code and add changes.

We try to make the functions easy to use and you're able to chain most of the component methods which increases usability a lot and it'll make your code shorter and easier to read.

# Example

Making gui with dx-gui is really easy:

```lua
-- Create a window
local win = Window(0, 0, 800, 600,'cool window')
win:align('center')

-- Add a couple of buttons
local btn1 = Button(50, 50, 150, 60, 'click me')
btn1:setParent(win)
btn1:on('click', function() btn1.value = 'clicked' end)

local btn2 = Button(50, 120, 150, 60, 'click me too')
btn2:setParent(win)
btn2:on('click', function() btn2.value = 'clicked' end)
```

# License

Copyright 2018 Tails

Licensed under the LGPLv3: https://www.gnu.org/licenses/lgpl-3.0.html
