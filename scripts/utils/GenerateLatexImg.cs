using Godot;
using System;
using SkiaSharp;
using CSharpMath.SkiaSharp;
using System.Xml.XPath;

[GlobalClass]
public partial class GenerateLatexImg : Node
{
	public ImageTexture GetImage(string expr, int font_size, int error_size)
	{
        var painter = new MathPainter();
        painter.LaTeX = expr;
        painter.FontSize = font_size;
        painter.ErrorFontSize = error_size;
        painter.TextColor = new SKColor(255, 255, 255);

        var measure = painter.Measure();
        int width = (int)Math.Ceiling(measure.Width);
        int height = (int)Math.Ceiling(measure.Height);
        var info = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);

        using (var bitmap = new SKBitmap(info))
        using (var canvas = new SKCanvas(bitmap))
        {
            canvas.Clear(SKColors.Transparent);
            painter.Draw(canvas);

            if (width * height == 0) { return null; }

            var img = Image.CreateFromData(
                width,
                height,
                false,
                Image.Format.Rgba8,
                bitmap.Bytes
            );

            return ImageTexture.CreateFromImage(img);
        }
    }
}
