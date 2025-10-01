# Happy Notes - Take notes as easily as tweeting
[中文](./README.cn.md)

HappyNotes is a simple yet powerful note-taking app that supports all platforms.

## Why is it called HappyNotes?

The name was inspired by HappyFeed, of which I was a heavy user of the free version. I must say it's quite good if your goal is just to write a diary. Oh, I almost went off-topic recommending HappyFeed, but you're still welcome to use HappyNotes. Happy notes, recording your happy life. What a great vision! But life isn't always sunny, so I also record some other journeys of the mind. Stop! Let's focus on recording more happy moments in life!

## Why not use other existing note-taking software?

Firstly, the free versions of these apps have too many limitations! Another reason is that although I'm a programmer, my product manager dream is still burning! I want to create an app that at least I enjoy using to <del>"prove" myself</del> give back to society.

## What's special about HappyNotes?

### 1. Text is King

HappyNotes allows you to upload photos, but once a photo is successfully uploaded, it becomes part of your note, as a Markdown image text (`![imageTitle](imageUrl)`) format. 

### 2. Supports private text, but not private photos

This means that even if a note is private, the photos in it are public. This eliminates the possibility of private photo leaks from the source! Simply don't upload private photos. Remember: The cloud brings convenience but reduces security.

- The pencil icon in the top right is for writing public notes by default
  - There's an option in settings to override this default, making all note-writing entries default to private notes
- The + icon in the main navigation is for writing private notes by default
- Photos are hosted on HappyNotes' image server, and anyone who knows the image URL can access your photos. Important thing to say three times: **Please do not upload private photos. Please do not upload private photos. Please do not upload private photos**.

### 3. Supports viewing notes/diaries by day

- Want to know how you spent your birthday last year? Tap the `My Notes title`, enter a date, and you'll go straight to that day's notes. Want to see the day before? HappyNotes allows you to browse the previous and next day from any day's note page. It's like your paper notebook, flip to a certain day, keep flipping forward for the next day, or backward for the previous day.
- There's actually a bonus here! When you enter a date, besides seeing the notes for that date, HappyNotes also allows you to add any number of additional notes on that day. There's a + button in the bottom right corner of the note list for a particular day. Clicking that button allows you to write a new note for that date. The date will be that day, while the time will be the creation time of the note. For example, if you're adding a note on the page for January 1, 1989, and you submit the note at 12:00 on January 1, 2025, the publication time of this note will be 12:00 on January 1, 1989. I hope I've made myself clear.

### 4. Supports viewing notes by Tag

- In the note list, tags for each note are listed. Clicking on any tag will show all notes marked with that tag. Don't see the tag you want to view on the current page? Tap the My Notes title, enter the text of that tag, and you'll go straight to that tag's dedicated page. Convenient, right?!
- Long press the My Notes title, and you'll see a Tag cloud. You can click on any Tag in this cloud to view all notes marked with that Tag.


### 5. Supports jumping to notes by ID

- In any note list, you can long press on the metadata row (the blue line with date, time and note ID) to open a dialog for jumping to a specific note by its ID.
- Simply enter the note ID number and press "Go" to navigate directly to that note.
- This feature provides quick access to specific notes when you know their ID, useful for referencing notes from external links or bookmarks.

### 6. Supports uploading or pasting images

- Currently, you need to enable Markdown support in the note editing interface to upload images. Just tap the Markdown switch below the edit box to turn this feature on/off. You can also turn Markdown support on/off in Settings -> Markdown.

### 7. Supports syncing notes to Telegram channels

You can choose to sync all notes, or only public notes, or only private notes, or only notes with specific Tags to a Telegram channel. I don't recommend syncing your private notes to a public Telegram channel. However, if you insist on doing so, HappyNotes won't stop you. I usually create a private channel to sync all my notes, which serves as a backup.

### 8. Supports syncing specified notes to Mastodon

You can choose to sync all notes, or only public notes, or only notes with the Mastodon tag to a Mastodon instance. Private notes will be published as private toots. Notes longer than 500 characters will be published as long images.

- If you change a public note to private or vice versa, the originally synced toot will be deleted and reposted. Therefore, the Mastodon timeline may not be consistent with your note timeline.
- Since Mastodon doesn't support Markdown, the first four images in Markdown notes will be synced to the media server of the Mastodon instance. To some extent, this Mastodon instance serves as a backup for your note images.

### 9. Supports "Discovering" others' public notes (This feature is currently only available on Web, maybe later it will be opened to native Apps)

### 10. Other tips
- **Edit Notes**: Double-tap a note to make changes.
- **Tags**: Create tags by adding `#example_tag` in your notes.
- **Note Details**: Tap creation time or `View more` for details.
- **Navigation**: Long press page numbers to jump to a specific page.
- **Settings**:
  - Adjust page size.
  - Set your timezone.
  - Enable Markdown support.

## Join Our Community

Connect with us on Telegram for support and to share experiences:

[Happy Notes Support Group](https://t.me/happynotes_support)

Let's support each other and make the most of HappyNotes!

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.


