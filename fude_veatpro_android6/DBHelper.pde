import android.content.Context;
import android.content.ContentValues;

import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.database.Cursor;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Date;

public class DatabaseHelper extends SQLiteOpenHelper {

    private static final String DATABASE_NAME = "drawings.db";
    private static final int DATABASE_VERSION = 2;

    public static final String TABLE_DRAWING = "drawings";
    public static final String COLUMN_ID = "id";
    public static final String COLUMN_TITLE = "title";
    public static final String COLUMN_DATE = "date";
    public static final String COLUMN_IMAGE_DATA = "image_data";  // 画像データを保存

    private static final String TABLE_CREATE =
            "CREATE TABLE " + TABLE_DRAWING + " (" +
                    COLUMN_ID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
                    COLUMN_TITLE + " TEXT, " +
                    COLUMN_DATE + " TEXT, " +
                    COLUMN_IMAGE_DATA + " BLOB);";  // ファイルパスをTEXT型で保存

    public DatabaseHelper(Context context) {
        super(context, DATABASE_NAME, null, DATABASE_VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(TABLE_CREATE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        db.execSQL("DROP TABLE IF EXISTS " + TABLE_DRAWING);
        onCreate(db);
    }

    public void saveDrawing(String title, byte[] imageBytes) {
        SQLiteDatabase db = this.getWritableDatabase();
        ContentValues values = new ContentValues();
        String currentDate = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(new Date());
        
        values.put(COLUMN_TITLE, title);
        values.put(COLUMN_IMAGE_DATA, imageBytes);  // ファイルパスを保存
        values.put(COLUMN_DATE, currentDate);
        db.insert(TABLE_DRAWING, null, values);
        db.close();
    }
}
