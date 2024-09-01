local RunService = game:GetService('RunService')

local UITweenService = {}
UITweenService.__index = UITweenService

function ServerPlay(self)
	print('서버플레이됨')
end

local Queue = {}

function update(delta)
	spawn(function()
		for i,Q in pairs(Queue) do
			Q.timeline += delta
			if Q.timeline >= Q.target.tweenInfo.Time then
				Q.target.Object[Q.key] = Q.value
				table.remove(Queue,table.find(Queue,Q))
			else
				Q.target.Object[Q.key] = Q.getNow(Q.timeline)
			end
		end
	end)
end
if RunService:IsServer() then
	RunService.Heartbeat:Connect(update)
else
	RunService.RenderStepped:Connect(update)
end

function ClientPlay(self)
	spawn(function()
		for key, value in pairs(self.Properties) do
			spawn(function()
				local timeline = 0
				local getNow = function(x)
				end
				if self.tweenInfo.Style == 'Linear' then
					if typeof(value) == 'number' then
						getNow = function(x)
							return ((value-self.Object[key])/self.tweenInfo.Time)*x+self.Object[key]
						end
					elseif typeof(value) == 'UDim2' then
						getNow = function(x)
							return UDim2.new(
								((value.X.Scale-self.Object[key].X.Scale)/self.tweenInfo.Time)*x+self.Object[key].X.Scale,
								((value.X.Offset-self.Object[key].X.Offset)/self.tweenInfo.Time)*x+self.Object[key].X.Offset,
								((value.Y.Scale-self.Object[key].Y.Scale)/self.tweenInfo.Time)*x+self.Object[key].Y.Scale,
								((value.Y.Offset-self.Object[key].Y.Offset)/self.tweenInfo.Time)*x+self.Object[key].Y.Offset
							)
						end
					end
				elseif self.tweenInfo.Style == 'Sine' then
					if self.tweenInfo.Direction == 'In' then
						if typeof(value) == 'number' then
							getNow = function(x)
								return (math.abs(value-self.Object[key])/2) * math.sin(((math.pi*2)/self.tweenInfo.Time)*x-math.pi/2)+(self.Object[key]+value)/2
							end
						elseif typeof(value) == 'UDim2' then
							getNow = function(x)
								return UDim2.new(
									(math.abs(value.X.Scale-self.Object[key].X.Scale)/2) * math.sin(((math.pi*2)/self.tweenInfo.Time)*x-math.pi/2)+(self.Object[key].X.Scale+value.X.Scale)/2,
									(math.abs(value.X.Offset-self.Object[key].X.Offset)/2) * math.sin(((math.pi*2)/self.tweenInfo.Time)*x-math.pi/2)+(self.Object[key].X.Offset+value.X.Offset)/2,
									(math.abs(value.Y.Scale-self.Object[key].Y.Scale)/2) * math.sin(((math.pi*2)/self.tweenInfo.Time)*x-math.pi/2)+(self.Object[key].Y.Scale+value.Y.Scale)/2,
									(math.abs(value.Y.Offset-self.Object[key].Y.Offset)/2) * math.sin(((math.pi*2)/self.tweenInfo.Time)*x-math.pi/2)+(self.Object[key].Y.Offset+value.Y.Offset)/2
								)
							end
						end
					end
				end
				local NewQueue = {
					getNow = getNow,
					target = self,
					timeline = 0,
					key = key,
					value = value
				}
				table.insert(Queue,NewQueue)
			end)
		end
	end)
end

function UITweenService:TweenCreate(Object : any, tweenInfo : {Time : number, Style : string, Direction : string},Properties : {name : string, targetValue : any})
	if not Object then return end
	local self = {}
	self.Object = Object
	self.tweenInfo = {
		Time = tweenInfo.Time,
		Style = tweenInfo.Style,
		Direction = tweenInfo.Direction
	}
	self.Properties = Properties
	return setmetatable(self,UITweenService)
end

function UITweenService.NewTweenInfo(_Time : number, _Style : string, _Direction : string)
	return {
		Time = _Time,
		Style = _Style,
		Direction = _Direction
	}
end

function UITweenService:Play()
	if RunService:IsServer() then
		ServerPlay(self)
	else
		ClientPlay(self)
	end
end

return UITweenService