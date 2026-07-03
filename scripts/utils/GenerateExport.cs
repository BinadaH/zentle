using CSharpMath.SkiaSharp;
using Godot;
using Godot.Collections;
using SkiaSharp;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;

[GlobalClass]
public partial class GenerateExport : Node
{

    Godot.Color bg_color;
    Godot.Color grid_color;
    SKTypeface fontTypeface = SKTypeface.Default;
    int sq_size = 0;
    int grid_w = 0;
    bool grid_on = true;


    public void SetupFont(FontFile font_file)
    {
        if (font_file != null)
        {
            using (SKData fontData = SKData.CreateCopy(font_file.Data))
            {
                this.fontTypeface = SKTypeface.FromData(fontData);
            }
        }
        else
        {
            this.fontTypeface = SKTypeface.Default;
        }
    }

    public void Setup(int sq_size, int grid_weight, Godot.Color bg_color, Godot.Color grid_color, bool grid_on)
    {
        this.bg_color = bg_color;
        this.grid_w = grid_weight;
        this.sq_size = sq_size;
        this.grid_color = grid_color;
        this.grid_on = grid_on;
    }

    private SKColor GDColor2SKColor(Godot.Color col)
    {
        return new SKColor((byte)(col.R * 255), (byte)(col.G * 255), (byte)(col.B * 255), (byte)(col.A * 255));
    }

	public byte[] ExportSvg(CanvasItem[] objs, Vector2 position, Vector2I size)
	{
		using (var stream = new SKDynamicMemoryWStream())
        { 
		    using(var canvas = SKSvgCanvas.Create(new SKRect(0, 0, size.X, size.Y), stream))
		    {
                HandleDraw(canvas, objs, position, size);
            }
                
            using (SKData data = stream.CopyToData())
            {
                return data.ToArray();
            }
        }
    }

    public byte[] ExportPdf(Array<Array<CanvasItem>> page_objs, Array<Vector2> page_positions, Array<Vector2I> page_sizes)
    {
        using (var stream = new SKDynamicMemoryWStream())
        {
            using (var document = SKDocument.CreatePdf(stream))
            {
                for (int i = 0; i < page_objs.Count; i++)
                {
                    CanvasItem[] objs = page_objs[i].ToArray<CanvasItem>();
                    Vector2 page_position = page_positions[i];
                    Vector2I size = page_sizes[i];

                    using (var canvas = document.BeginPage(size.X, size.Y))
                    {
                        HandleDraw(canvas, objs, page_position, size);
                    }
                    document.EndPage();
                    
                }
                document.Close();
            }

            using (SKData data = stream.CopyToData())
            {
                return data.ToArray();
            }

        }
    }

    private void HandleDraw(SKCanvas canvas, CanvasItem[] objs, Vector2 page_position, Vector2I size) 
    {
        using (var paint = new SKPaint())
        {
            DrawBackground(canvas, paint, size);
            if (grid_on)
                DrawGrid(canvas, paint, page_position, size);


            foreach (var item in objs)
            {
                if (item is Line2D line)
                {
                    DrawLine2D(line, page_position, paint, canvas);
                }
                else if (item.IsInGroup("text"))
                {
                    DrawText((Control)item, page_position, paint, canvas);
                }
            }
        }
    }


    private void DrawText(Control item, Vector2 page_position, SKPaint paint, SKCanvas canvas)
    {
        var text_lines = item.Call("get_line_nodes").AsGodotArray<Node>();
        var latex_blocks = item.Get("latex_blocks").AsStringArray();
        paint.Color = GDColor2SKColor(item.Get("curr_color").AsColor());
        float font_size = (float)item.Get("curr_font_size").AsDouble();
        var latex_i = 0;
        foreach (var text_line in text_lines)
        {
            foreach (var text_block in text_line.GetChildren())
            {
                if (text_block is Godot.RichTextLabel label)
                {
                    paint.Style = SKPaintStyle.Fill;

                    string txt = label.Text;
                    var obj_rect = label.GetGlobalRect();
                    var pos = obj_rect.Position - page_position;
                    var rect_height = obj_rect.Size.Y;
                    using (var font = new SKFont(fontTypeface, font_size))
                    {
                        SKPoint p = new SKPoint(pos.X, pos.Y + (font_size + rect_height) / 2);
                        canvas.DrawText(txt, p, SKTextAlign.Left, font, paint);
                    }
                }
                else if (text_block is Godot.TextureRect texture_rect)
                {
                    var pos = texture_rect.GetGlobalRect().Position - page_position;
                    var painter = new MathPainter();
                    var expr = latex_blocks[latex_i];
                    painter.LaTeX = expr;
                    painter.FontSize = font_size;
                    painter.TextColor = paint.Color;
                    var obj_rect = texture_rect.GetGlobalRect();

                    SKPoint p = new SKPoint(pos.X, pos.Y + (font_size + obj_rect.Size.Y) / 2);
                    painter.Draw(canvas, p);
                    latex_i += 1;
                }
            }
        }
    }

    private void DrawLine2D(Line2D line, Vector2 page_position, SKPaint paint, SKCanvas canvas)
    {
        paint.Style = SKPaintStyle.Stroke;
        paint.IsAntialias = true;
        paint.StrokeCap = SKStrokeCap.Round;
        paint.StrokeJoin = SKStrokeJoin.Round;
        paint.Color = new SKColor(
                                (byte)(line.DefaultColor.R * 255),
                                (byte)(line.DefaultColor.G * 255),
                                (byte)(line.DefaultColor.B * 255),
                                (byte)(line.DefaultColor.A * 255)
                            );
        if (line.Points.Length > 0)
        {
            Vector2[] points = line.Points;
            int count = points.Length;

            if (count < 2) return;

            float baseWidth = line.Width;
            Curve widthCurve = line.WidthCurve;

            Vector2 offsetTotal = line.Position - page_position;

            for (int i = 0; i < count - 1; i++)
            {
                Vector2 p1Shifted = points[i] + offsetTotal;
                Vector2 p2Shifted = points[i + 1] + offsetTotal;

                float t1 = (float)i / (count - 1);
                float t2 = (float)(i + 1) / (count - 1);
                float w1 = baseWidth * (widthCurve != null ? widthCurve.Sample(t1) : 1f);
                float w2 = baseWidth * (widthCurve != null ? widthCurve.Sample(t2) : 1f);

                float currentWidth = (w1 + w2) / 2f;
                paint.StrokeWidth = currentWidth;

                canvas.DrawLine(p1Shifted.X, p1Shifted.Y, p2Shifted.X, p2Shifted.Y, paint);
            }
        }

    }

    private void DrawBackground(SKCanvas canvas, SKPaint paint, Vector2I size)
    {
        paint.Style = SKPaintStyle.Fill;
        paint.Color = GDColor2SKColor(bg_color);
        canvas.DrawRect(new SKRect(0, 0, size.X, size.Y), paint);
    }

    private void DrawGrid(SKCanvas canvas, SKPaint paint, Vector2 page_position, Vector2I size)
    {
        paint.Style = SKPaintStyle.Stroke;
        paint.StrokeWidth = grid_w;
        paint.Color = GDColor2SKColor(grid_color);

        float offset_x = (float)(Godot.Mathf.Floor(page_position.X / sq_size) + 1) * sq_size - page_position.X;
        float offset_y = (float)(Godot.Mathf.Floor(page_position.Y / sq_size) + 1) * sq_size - page_position.Y;
        int num_x = (int)(size.X / sq_size);
        int num_y = (int)(size.Y / sq_size);

        for (int i = 0; i <= num_x; i++)
        {
            float posX = i * sq_size + offset_x;
            SKPoint p1 = new SKPoint(posX, 0);
            SKPoint p2 = new SKPoint(posX, size.Y);
            canvas.DrawLine(p1, p2, paint);
        }

        for (int j = 0; j <= num_y; j++)
        {
            float posY = j * sq_size + offset_y;
            SKPoint p1 = new SKPoint(0, posY);
            SKPoint p2 = new SKPoint(size.X, posY);
            canvas.DrawLine(p1, p2, paint);
        }
    }

}
