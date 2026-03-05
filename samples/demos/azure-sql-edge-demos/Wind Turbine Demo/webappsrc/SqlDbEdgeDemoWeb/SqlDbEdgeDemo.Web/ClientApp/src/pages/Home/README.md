# Route folder

This folder represents a top level route or 'page' in the application. The folder should only directly contain the `index.js` and the style file directly in the folder. 

- Any components should have their own folder and should be located the the sub-folder `components`. 
- Any assets should be located in a sub-folder `assets`.

Sometimes you will find a component or assets needs to be shared between multiple pages. This is when it 'graduates' into the appropriate shared folder in the `ClientApp/src`.