# Image Slicer
Utility app for slicing up images.

Created to cut up the
[Gregg Anniversary Edition](http://gregg.angelfishy.net/analphbt.shtml)
shorthand images for creating Anki cards.


## License
MPLv2, AKA non-contagious copy-left.

I dunno, I needed to pick something, and this is a good middleground
between "you can use my stuff" and "you can't just run off with it and go
wild", mmkay?


## Usage
- Create a new document.
- Drop an image where it says to.
- Add horizontal and vertical slices to delimit subregions of the image.
    - Note that order matters, since the horizontal or vertical slice expands
      out from where you click but stops at either the first image edge
      or other slice line that it hits. This works great for the tabular
      format of most of the Gregg images, so it works for me.
- Add marks to name subrects that you want exported.
- Click Export Marked Selections, pick a directory, and boom:
  Each mark named "foo" has a corresponding "foo.png" image in that directory.


## Obsoletes
- Open image in Preview.
- Select a square region.
- Copy.
- New from Clipboard.
- Save the new image.
- Move the region.
- Copy.
- … this is so slow and boring. And now there's an app to make it faster!


## Playground
The playground contains an early proof-of-concept (POC) for the core code.

I'd hoped to share this between the app and the playground using a framework,
but try as I might, it just wouldn't work.

So the playground contains old, POC code, while the app itself is using
a newer, modified version of that code.


## Ugly Stuff
- The tests. What tests? Exactly. This is a small enough app that the entire
  core functionality gets exercised each and every time I use it, so I didn't
  worry about automating tests. If anything is broken, I'll know it first
  thing. And thanks to the document architecture, I can bookmark a point in
  time and pick up from there to test a single broken workflow step.
